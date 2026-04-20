#!/usr/bin/env bash
#
# fetch-failures.sh
# Fetch an HTML results page, find all links marked "F" (failed tests),
# and copy those result folders from the network mount to a local directory.
#
# The network share (e.g. \\storage-stc.cal.viavi.io\results) must already
# be mounted at /Volumes/results (or another path the user specifies).

set -euo pipefail

RESULTS_MOUNT="/Volumes/results"

# ── Python snippet used to parse the HTML ────────────────────────────────────
PARSE_SCRIPT=$(cat <<'PYEOF'
import sys, re

html = sys.stdin.read()

# Match href="..." links whose visible text is exactly "F"
# href may contain Windows backslash paths; >F< may have surrounding whitespace
pattern = r'href="([^"]+)"[^>]*>\s*F\s*</a>'
matches = re.findall(pattern, html)

seen = set()
for m in matches:
    if not m.lower().startswith('file:///'):
        continue
    # Remove file:/// prefix and normalise backslashes → forward slashes
    path = m[8:].replace('\\', '/').lstrip('/')
    # Strip the server + share prefix up to and including /results/
    # e.g.  storage-stc.cal.viavi.io/results/SCMSmartTest/... → SCMSmartTest/...
    idx = path.find('/results/')
    if idx == -1:
        # Maybe the share is literally the root (no /results/ component)
        continue
    rel = path[idx + len('/results/'):]   # relative path inside the share
    # The last component is the test-case folder (e.g. "TC42--foo.tcl" or
    # "TC42--foo.tcl -RERUN"). Strip any trailing " -RERUN" annotation.
    parts = rel.rstrip('/').split('/')
    if len(parts) < 1:
        continue
    parts[-1] = re.sub(r'\s+-RERUN\s*$', '', parts[-1]).strip()
    folder = '/'.join(parts)
    if folder not in seen:
        seen.add(folder)
        print(folder)
PYEOF
)

# Extract the AllFails detail-page URL from a suite overview page.
# Takes the original page URL as argv[1] so it can resolve relative hrefs.
FIND_ALLFAILS_SCRIPT=$(cat <<'PYEOF'
import sys, re
from urllib.parse import urljoin, quote

page_url = sys.argv[1]
html = sys.stdin.read()
m = re.search(r'href="(/stapp/suite_summary_detail_table/[^"]*detail=AllFails[^"]*)"', html)
if m:
    path = m.group(1)
    # URL-encode spaces and special chars in the path while keeping / ? = & intact
    safe_chars = '/?=&%'
    encoded = quote(path, safe=safe_chars)
    full = urljoin(page_url, encoded)
    print(full)
PYEOF
)

# ── Helpers ───────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "$*"; }

# ── Prompt for inputs ─────────────────────────────────────────────────────────
echo "=== SmartTest failure folder downloader ==="
echo

printf "HTML page URL: "
read -r PAGE_URL
[[ -n "$PAGE_URL" ]] || die "URL must not be empty."

printf "Local destination base folder [default: ./results]: "
read -r DEST_BASE
DEST_BASE="${DEST_BASE:-./results}"
DEST_BASE="${DEST_BASE%/}"   # strip trailing slash

printf "Network results mount point [default: %s]: " "$RESULTS_MOUNT"
read -r USER_MOUNT
[[ -n "$USER_MOUNT" ]] && RESULTS_MOUNT="${USER_MOUNT%/}"

echo
info "Fetching page: $PAGE_URL"
HTML=$(curl -sk "$PAGE_URL") || die "curl failed – check URL and network access."
[[ -n "$HTML" ]] || die "Page returned empty content."

# ── Extract unique folders ────────────────────────────────────────────────────
info "Parsing F-marked links..."

# Build folder list (newline-separated) via Python
RAW_FOLDERS=$(echo "$HTML" | python3 -c "$PARSE_SCRIPT")

if [[ -z "$RAW_FOLDERS" ]]; then
    # No F links on this page – check if it's a suite overview that links to AllFails
    ALLFAILS_URL=$(echo "$HTML" | python3 -c "$FIND_ALLFAILS_SCRIPT" "$PAGE_URL")
    if [[ -z "$ALLFAILS_URL" ]]; then
        info "No links marked 'F' found, and no AllFails sub-page detected."
        exit 0
    fi
    info "Suite overview detected – following AllFails page:"
    info "  $ALLFAILS_URL"
    HTML=$(curl -sk "$ALLFAILS_URL") || die "curl failed fetching AllFails page."
    [[ -n "$HTML" ]] || die "AllFails page returned empty content."
    RAW_FOLDERS=$(echo "$HTML" | python3 -c "$PARSE_SCRIPT")
    if [[ -z "$RAW_FOLDERS" ]]; then
        info "No failures (F) found on the AllFails page either."
        exit 0
    fi
fi

# Read into an array (works in bash 3.2+ with a while loop)
FOLDERS=()
while IFS= read -r folder; do
    [[ -n "$folder" ]] && FOLDERS+=("$folder")
done <<< "$RAW_FOLDERS"

# ── Show what we found ────────────────────────────────────────────────────────
echo
echo "Found ${#FOLDERS[@]} unique folder(s) containing failures:"
echo
MISSING=0
for folder in "${FOLDERS[@]}"; do
    src="${RESULTS_MOUNT}/${folder}"
    if [[ -d "$src" ]]; then
        printf "  [found]   %s\n" "$src"
    else
        printf "  [MISSING] %s\n" "$src"
        ((MISSING++)) || true
    fi
done

echo
echo "Destination base : $DEST_BASE"
if [[ $MISSING -gt 0 ]]; then
    echo "WARNING: $MISSING folder(s) not found at mount point – they will be skipped."
fi
echo

# ── Confirm ───────────────────────────────────────────────────────────────────
printf "Proceed with copy? [y/N] "
read -r CONFIRM
case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss]) ;;
    *) echo "Aborted."; exit 0 ;;
esac

# ── Copy ──────────────────────────────────────────────────────────────────────
echo
ERRORS=0
for folder in "${FOLDERS[@]}"; do
    src="${RESULTS_MOUNT}/${folder}"
    dest="${DEST_BASE}/${folder}"

    if [[ ! -d "$src" ]]; then
        echo "SKIP (not found): $src"
        ((ERRORS++)) || true
        continue
    fi

    dest_parent="${dest%/*}"
    mkdir -p "$dest_parent" || { echo "ERROR: cannot create $dest_parent"; ((ERRORS++)) || true; continue; }

    echo "Copying: $src"
    echo "     to: $dest"
    if rsync -a --progress "$src/" "$dest/"; then
        echo "    OK"
        # Unzip any .zip files in the copied folder
        while IFS= read -r -d '' zipfile; do
            echo "  Unzipping: $zipfile"
            unzip -q -o "$zipfile" -d "$(dirname "$zipfile")" || echo "    WARNING: unzip failed for $zipfile"
        done < <(find "$dest" -name "*.zip" -print0)
    else
        echo "    ERROR (rsync exit $?)"
        ((ERRORS++)) || true
    fi
    echo
done

# ── Summary ───────────────────────────────────────────────────────────────────
if [[ $ERRORS -eq 0 ]]; then
    echo "All ${#FOLDERS[@]} folder(s) copied successfully."
else
    echo "Done with $ERRORS error(s) out of ${#FOLDERS[@]} folder(s)."
    exit 1
fi

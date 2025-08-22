import os
import re

REGEX = re.compile('\\+.* sec')

def scan(path, counts):
    with open(path, 'rb') as f:
        lines = f.readlines()
        for l in lines:
            line = str(l)
            if 'perf.fmwk.bll.apply  - **Slow**' in line:
                m = REGEX.search(line)
                if m is not None:
                    tokens = m.group().split(' ')
                    # remove spaces
                    tokens = [t for t in tokens if t]
                    applyTimes = counts.get(path, [])
                    applyTimes.append((tokens[1], tokens[2]))
                    counts[path] = applyTimes


counts = dict()

for root, dirs, files, in os.walk("."):
    files = [f for f in files if f == 'bll.log']
    for file in files:
        path = os.path.join(root, file)
        scan(path, counts)

# Write to csv
with open('apply_times.csv', 'w') as f:
    for k, v in counts.items():
        for t in v:
            f.write(k) # log file
            f.write(', ')
            f.write(t[0]) # category
            f.write(', ')
            f.write(t[1]) # time in sec
            f.write('\n')

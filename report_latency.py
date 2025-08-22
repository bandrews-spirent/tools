import json
from datetime import datetime

file = 'orion-res.trace.json'

def createDateTime(s):
    FMT = '%Y-%m-%dT%H:%M:%S.%f'
    return datetime.strptime(s[:-7], FMT)

with open(file, 'r') as json_file:
    for line in json_file:
        data = json.loads(line)
        start = createDateTime(data['start'])
        finish = createDateTime(data['finish'])
        diff = finish - start
        if diff.seconds >= 2:
            print json.dumps(data)
            total = {"total_time_sec": diff.seconds}
            print json.dumps(total)

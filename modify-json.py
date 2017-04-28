import json
import sys

for arg in sys.argv:
    print arg
# Read config.json file
with open('./change-resource-record-sets.json') as data_file:
    config = json.load(data_file)
    data_file.close()
    config["Changes"][0]["ResourceRecordSet"]["ResourceRecords"][0]["Value"]=arg
    print config

    data_file = open("./change-resource-record-sets.json", "w+")
    data_file.write(json.dumps(config))
    data_file.close()

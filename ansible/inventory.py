#!/usr/bin/env python3

# Modules
import json, re, argparse, sys

# Static
RESOURCES = {}
OUTPUT = { 'all': { 'children': [ "ungrouped" ] }, "_meta": { "hostvars": {} }, "ungrouped": { 'children' : {}}}

# functions
## args
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", "-f", default='terraform.tfstate', help="Select a specific file")
    parser.add_argument("--list", "-l", action="store_true" ,help="Collect information from tfstate file")
    parser.add_argument("--host", help='Display information about host')
    args = parser.parse_args()
    return args

## read file
def load_file(filename):
    try:
        with open(filename, 'r') as tfstate:
            json_data = json.loads(tfstate.read())
    except FileNotFoundError:
        return print('File not found:', filename)
    except json.decoder.JSONDecodeError:
        return print('Not a json file'), sys.exit(1)
    return json_data

## get all resources as new dict
def get_resource(json_data):
    try:
        for module_index in range(len(json_data['modules'])):
            RESOURCES.update(json_data['modules'][module_index]['resources'])

        for resource in RESOURCES:
            reObj = re.compile('google_compute_instance')

            if reObj.match(resource):

                module, resource_name, *instance = resource.split('.')
                host_name = RESOURCES[resource]['primary']['attributes']['name']
                host_ip = RESOURCES[resource]['primary']['attributes']['network_interface.0.access_config.0.nat_ip']

                if not bool(OUTPUT['all']['children'].count(resource_name)):
                    OUTPUT.update({resource_name: {'hosts': []}})
                    OUTPUT['all']['children'].append(resource_name)

                OUTPUT["_meta"]["hostvars"].update({ host_name: { 'ansible_host': host_ip }})
                OUTPUT[resource_name]["hosts"].append(host_name)
        
        # Selected host output
        if args.host:
            return print(json.dumps(OUTPUT['_meta']['hostvars'].get(args.host), indent=4)) if OUTPUT['_meta']['hostvars'].get(args.host) else print("{}")

    except (KeyError, TypeError):
        return print("Not a .tfstate file")

    return print(json.dumps(OUTPUT, indent=4))

# MAIN
if __name__ == "__main__":
    args = parse_args()
    json_data = load_file(args.file)
    if args.list or args.host:
        get_resource(json_data)

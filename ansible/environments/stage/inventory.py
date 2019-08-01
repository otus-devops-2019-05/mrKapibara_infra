#!/usr/bin/env python3

# Modules
import json, re, argparse, sys, os
from google.cloud import storage

# Static
RESOURCES = {}
OUTPUT = { 'all': { 'children': [ "ungrouped" ] }, "_meta": { "hostvars": {} }, "ungrouped": { 'children' : {}}}

# Vars
# path to tfstate file: "gs://bucket-name/path/default.tfstate" or "/path/to/terraform.tfstate"
file_path = "gs://devops-otust-test-bckt/infra/stage/default.tfstate"
# Path to credentials file
# https://cloud.google.com/storage/docs/reference/libraries
account_file = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

# functions
# args
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--account", "-a", default=account_file, help="Path to authentication credentials")
    parser.add_argument("--file", "-f", default=file_path, help="Path to local or remote .tfstate file")
    parser.add_argument("--host", help='Display information about host')
    parser.add_argument("--list", "-l", action="store_true" ,help="Collect information from tfstate file")
    args = parser.parse_args()
    return args

# Check local or cloud file
def source_file(file_path):
    if re.match(r'^(gs:\/\/)', file_path):
        return gcloud_file(file_path)
    else:
        return local_file(file_path)

# read cloud file
def gcloud_file(gpath):
    v1, v2, bucket_name, *bucket_path = gpath.split("/")
    bucket_path = "/".join(bucket_path)

    if args.account:
        client = storage.Client.from_service_account_json(args.account)
    else:
        client = storage.Client()

    try:
        bucket = client.get_bucket(bucket_name)
    except Exception:
        return print("Can't connect to bucket:", bucket_name), sys.exit(1)

    blob = bucket.get_blob(bucket_path)
    try:
        json_data = blob.download_as_string()
    except Exception:
        return print('File not found', bucket_path), sys.exit(1)
    return json.loads(json_data)

# read local file
def local_file(filename):
    try:
        with open(filename, 'r') as tfstate:
            json_data = json.loads(tfstate.read())
    except FileNotFoundError:
        return print('File not found:', filename), sys.exit(1)
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
    json_data = source_file(args.file)
    if args.list or args.host:
        get_resource(json_data)

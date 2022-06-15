import argparse
from datetime import datetime
import json
import logging
import sys
import ipfshttpclient

log = logging.getLogger(__name__)


def configureLogging():
    formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s',
                                  '%m-%d-%Y %H:%M:%S')

    log.setLevel(logging.INFO)

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.INFO)
    stdout_handler.setFormatter(formatter)

    log.addHandler(stdout_handler)


def throwIfMissingElement(typeName, elementname, content):
    if elementname not in content:
        raise Exception(f'A {typeName} must contain the element \"{element}\".')


def validateNode(content):
    possibleNode = json.loads(content)
    if len(possibleNode) > 0:
        throwIfMissingElement("node", "nodeid", possibleNode)
        throwIfMissingElement("node", "fileid", possibleNode)


def validateRelationship(content):
    possibleRelationship = json.loads(content)
    if len(possibleRelationship) > 0:
        throwIfMissingElement("relationship", "nodeida", possibleRelationship)
        throwIfMissingElement("relationship", "nodeidb", possibleRelationship)


def validateArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--ipfsapiserver", action="store",
                        help="The address of the IPFS API (e.g. /dns/localhost/tcp/5001/http)", required=False, default="/dns/ipfs-ui/tcp/5001/http")
    parser.add_argument("-g", "--graphfile", action="store",
                        help="The name of the file representing the graph", required=True)
    parser.add_argument("-n", "--node", action="store",
                        help="A node to add", required=False)
    parser.add_argument("-r", "--relationship", action="store",
                        help="A relationship to add", required=False)

    args = parser.parse_args()

    client = ipfshttpclient.connect(args.ipfsapiserver)

    validateNode(args.node)
    validateRelationship(args.relationship)

    return (client, args.graphfile, args.node, args.relationship)


if __name__ == "__main__":
    starttime = datetime.utcnow()

    print("hi")
    configureLogging()
    (client, graphfile, node, relationship) = validateArgs()

    log.info("Graph file: %s", graphfile)
    log.info("Node: %s", node)
    log.info("Relationship: %s", relationship)

    response = client.add('test.txt')
    log.info(response)

    endtime = datetime.utcnow()
    log.info(
        "Done modifying graph file. Execution completed in %s", endtime-starttime)

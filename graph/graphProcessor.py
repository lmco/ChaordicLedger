import argparse
from datetime import datetime
import io
import json
import logging
import sys
import ipfshttpclient

log = logging.getLogger(__name__)


def configureLogging():
    formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s',
                                  '%Y-%m-%dT%H:%M:%SZ')

    log.setLevel(logging.DEBUG)

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.DEBUG)
    stdout_handler.setFormatter(formatter)

    log.addHandler(stdout_handler)


def throwIfMissingElement(typeName, elementname, content):
    if elementname not in content:
        raise Exception(
            f'A {typeName} must contain the element \"{elementname}\".')


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


def validateMode(mode):
    if mode is None or mode not in ["init", "read", "write"]:
        raise Exception(
            f"Invalid mode: {mode}. Valid modes: [init|read|write]")


def validateArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--ipfsapiserver", action="store",
                        help="The address of the IPFS API (e.g. /dns/localhost/tcp/5001/http)", required=False, default="/dns/ipfs-ui/tcp/5001/http")
    # parser.add_argument("-g", "--graphfile", action="store",
    #                     help="The name of the file representing the graph", required=True, default="graph.json")
    parser.add_argument("-m", "--mode", action="store",
                        help="Execution mode: [init|read|write]", required=False, default="init")
    parser.add_argument("-n", "--node", action="store",
                        help="A node to add", required=False)
    parser.add_argument("-r", "--relationship", action="store",
                        help="A relationship to add", required=False)

    args = parser.parse_args()

    client = ipfshttpclient.connect(args.ipfsapiserver)

    validateMode(args.mode)
    validateNode(args.node)
    validateRelationship(args.relationship)

    return (client, args.mode, args.node, args.relationship)


if __name__ == "__main__":
    starttime = datetime.utcnow()

    configureLogging()
    (client, mode, node, relationship) = validateArgs()

    log.info("Mode: %s", mode)
    log.info("Node: %s", node)
    log.info("Relationship: %s", relationship)

    jsonNode = json.loads(node)
    jsonRelationship = json.loads(relationship)

    if mode == "init":
        initialGraphState = {
            "nodes": [],
            "edges": []
        }

        # with open("/graph.json", "wb") as f:
        #     json.dump(initialGraphState, f)

        jsonStr = json.dumps(initialGraphState)
        #response = client.files.write("/", jsonStr.encode('utf-8'))
        #response = client.files.write("/graph.json", "graph.json")
        response = client.files.write(
            "/graph.json", io.BytesIO(jsonStr.encode('utf-8')), create=True, truncate=True)
        log.info(response)
    elif mode == "read":
        response = client.files.read("/graph.json")
        log.info(response.decode())
    elif mode == "write":
        jsonData = json.loads(client.files.read(
            "/graph.json").decode('utf-8)'))
        if len(jsonNode) > 0:
            log.info("Appending node: %s", node)
            jsonData["nodes"].append(jsonNode)

        if len(jsonRelationship) > 0:
            log.info("Appending relationship: %s", relationship)
            jsonData["edges"].append(jsonRelationship)

        jsonStr = json.dumps(jsonData)
        log.info("Writing updated graph content: %s", jsonStr)
        response = client.files.write(
            "/graph.json", io.BytesIO(jsonStr.encode('utf-8')), create=True, truncate=True)
        log.info("Response from IPFS File API Client: %s", response)
    else:
        log.error("Invalid mode %s provided.", mode)

    endtime = datetime.utcnow()
    log.info(
        "Done modifying graph file. Execution completed in %s", endtime-starttime)

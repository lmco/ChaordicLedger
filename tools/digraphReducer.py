import argparse
import logging
import json
import os
import requests
import sys
from datetime import datetime
from graphviz import Digraph


# https://graphviz.readthedocs.io/en/stable/examples.html
# https://www.graphviz.org/pdf/dotguide.pdf

node_color_defaults = {
    "border": "black",
    "fill": "white",
    "label": "black"
}

log = logging.getLogger(__name__)

def configureLogging(outdir):
    formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s',
                                  '%m-%d-%Y %H:%M:%S')

    log.setLevel(logging.INFO)

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.INFO)
    stdout_handler.setFormatter(formatter)

    file_handler = logging.FileHandler(os.path.join(
        outdir, f"{datetime.now().isoformat().replace(':','_').split('.')[0]}.log"))
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    log.addHandler(file_handler)
    log.addHandler(stdout_handler)

def add_node(artifactInfo: dict, dotgraph: Digraph):
    # Ref: https://web.mit.edu/spin_v4.2.5/share/graphviz/doc/html/info/shapes.html

    artifactNodeID = artifactInfo["NodeID"]
    artifactFileID = artifactInfo["FileID"]

    nodelabel = f'{artifactFileID}\\n(Object ID: {artifactNodeID}'

    dotgraph.node(artifactNodeID, label=nodelabel, shape='box', style='filled',
                  color="black", fillcolor="gray", fontcolor="black")


def add_edge(a: str, b: str, dotgraph: Digraph):
    dotgraph.edge(a, b, weight='0.1')


def generate_graph_file(outdir: str, file_name_prefix: str, dotgraph: Digraph):
    os.makedirs(outdir, exist_ok=True)
    filename = os.path.join(
        outdir, f'{file_name_prefix}RelationshipDigraph.gv')
    dotgraph.save(filename)
    log.info("Generated %s", filename)
    return filename


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Get relationship graph')
    parser.add_argument('-t', '--title',
                        help="The graph's title.", required=True)
    parser.add_argument('-p', '--prefix',
                        help="The output file's prefix.", required=True)
    parser.add_argument('-o', '--outDir',
                        help='The output location.', required=True)
    parser.add_argument('-r', '--rootArtifact',
                        help='The artifact from which the graph should be started.', required=True)
    parser.add_argument('-d', '--maxDepth',
                        help='The maximum relationship depth to explore.', required=False, type=int, default=3)

    parser.add_argument('-f', '--file',
                        help='Optional file to process. If not given, the live graph is pulled from the ledger.', required=False)

    args = parser.parse_args()

    configureLogging(args.outDir)

    if args.file is None:
        url = "http://localhost:8080/v1/relationships/getRelationshipGraphFile"
        log.info(f"Accessing {url} to retrieve relationship data.")
        response = requests.get(url)
        data = json.loads(response.text)
    else:
        log.info(f"Accessing {args.file} to retrieve relationship data.")
        with open(args.file, 'r') as f:
            data = json.load(f)

    title = args.title
    dotgraph = Digraph(name=title,
                       graph_attr={
                           "ranksep": "3",
                           "ratio": "auto"
                       })

    if args.maxDepth < 1:
        log.error("Invalid max depth")

    else:
        located = False
        for node in data["nodes"]:
            if node["NodeID"] == args.rootArtifact:
                #add_node(node, dotgraph)
                located = True
                break

        if located:
            log.info(f"Located specified root artifact {args.rootArtifact}")

            level = 0
            nodesIdsToProcess=set()
            nodesIdsToProcess.add(args.rootArtifact)
            processedNodes=set()
            while level < args.maxDepth:
                for node in nodesIdsToProcess.copy():
                    for dataNode in data["nodes"]:
                        if dataNode["NodeID"] == node:
                            add_node(dataNode, dotgraph)
                            break

                    log.info(f"Level {level}: Processing node {node}")
                    for edge in data["edges"]:
                        if edge["NodeIDA"] == node:
                            add_edge(edge["NodeIDA"], edge["NodeIDB"], dotgraph)
                            if edge["NodeIDA"] not in processedNodes and edge["NodeIDB"] not in processedNodes:
                                nodesIdsToProcess.add(edge["NodeIDB"])
                    #print(nodesIdsToProcess)
                    nodesIdsToProcess.remove(node)
                    processedNodes.add(node)
                level += 1
            
            # Include info for remaining linked nodes.
            for node in nodesIdsToProcess.copy():
                for dataNode in data["nodes"]:
                    if dataNode["NodeID"] == node:
                        add_node(dataNode, dotgraph)
                        break
        else:
            log.error(f"Could not locate specified root artifact {args.rootArtifact}")

        # Make a file in all cases.
        dotFileName = generate_graph_file(
                args.outDir, args.prefix.replace(" ", ""), dotgraph)

        log.info(f"Created GraphViz file {dotFileName}")

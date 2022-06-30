import argparse
import logging
import json
import os
import requests
from graphviz import Digraph

# https://graphviz.readthedocs.io/en/stable/examples.html
# https://www.graphviz.org/pdf/dotguide.pdf

node_color_defaults = {
    "border": "black",
    "fill": "white",
    "label": "black"
}

log = logging.getLogger(__name__)


def add_node(artifactInfo: dict, dotgraph: Digraph):
    # Ref: https://web.mit.edu/spin_v4.2.5/share/graphviz/doc/html/info/shapes.html

    artifactNodeID = artifactInfo["NodeID"]
    artifactFileID = artifactInfo["FileID"]

    nodelabel = f'{artifactFileID}\\n(Object ID: {artifactNodeID}'

    dotgraph.node(artifactFileID, label=nodelabel, shape='box', style='filled',
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
    parser.add_argument('-o', '--outdir',
                        help='The output location.', required=True)

    args = parser.parse_args()

    graphattributes = {
        # "concentrate": "true",
        # "rankdir": "BT",
        "ranksep": "3",
        # "nodesep": "2",
        # "orientation": "landscape",
        "ratio": "auto",
        "area": "3"  # Only used by patchwork.
    }

    url = "http://localhost:8080/v1/relationships/getRelationshipGraph"
    log.info(f"Accessing {url} to retrieve relationship data.")
    response = requests.get(url)

    title = args.title
    dotgraph = Digraph(name=title,
                       graph_attr=graphattributes)

    data = json.loads(response.text)["result"]

    for node in data["nodes"]:
        add_node(node, dotgraph)

    for edge in data["edges"]:
        add_edge(edge["NodeIDA"], edge["NodeIDB"], dotgraph)

    dotfilename = generate_graph_file(
        args.outdir, args.prefix.replace(" ", ""), dotgraph)

    # image_type = "svg"
    # processor = "dot" # circo, dot, fdp, neato, osage, twopi, patchwork
    # dot_file_name = "artifactRelationships"

    # outfile = f'{dot_file_name}_{processor}.{image_type}'
    # command = [processor, dot_file_name, f'-T{image_type}', "-o", outfile]

    # with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
    #     process.communicate()

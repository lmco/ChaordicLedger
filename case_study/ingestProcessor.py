import argparse
import pandas as pd
import httpx
import json
import os
import tempfile
from datetime import datetime, timezone
from treelib import Tree


def ingestHierarchy(csvFile: str):
    df = pd.read_csv(csvFile, dtype="U")

    tree = Tree()

    for index, row in df.iterrows():
        parentBinding = str(row["parentBinding"])
        name = str(row["Name"])
        tag = str(row["Artifact Type"])

        if parentBinding == "nan":
            parentBinding = None

        tree.create_node(tag, name, parentBinding, data=row["Primary Text"])

    return tree


def uploadToLedger(tree: Tree, ledgerURL: str):
    ipfsNameCache = {}

    for node in tree.all_nodes_itr():
        # Only need to upload headers and requirements.
        if node.tag == "Header" or node.tag == "Requirement":
            name=f'{node.identifier}.{node.tag.lower()}'
            print(f"Uploading: {name}")

            tempdir = tempfile.gettempdir()
            filename = os.path.join(tempdir, name)

            with open(filename, 'w') as f:
                f.writelines([node.identifier, os.linesep, node.tag, os.linesep, datetime.now(
                    timezone.utc).isoformat(), os.linesep, node.data, os.linesep])

            createArtifactEndpoint = f'{ledgerURL}/artifacts/createArtifact'

            # Upload the artifact.
            artifactIPFSName = None
            with open(filename, 'rb') as f:
                files = {'upfile': (filename, f, 'multipart/form-data')}
                r = httpx.post(createArtifactEndpoint, files=files)
                print(r.status_code)
                print(r.text)
                artifactIPFSName = json.loads(r.text)["result"]["result"]["IPFSName"]

            ipfsNameCache[node.identifier] = artifactIPFSName

            # Processing of the tree is sequential, so the IPFS name for any parent node
            # will be in the cache.
            parentNode=tree.parent(node.identifier)
            if parentNode is not None:
                parentIPFSname = ipfsNameCache[parentNode.identifier]

                # Relate the artifact to its parent requirement artifact.
                createRelationshipEndpoint = f'{ledgerURL}/relationships/createRelationship'
                print(
                    f'Relating {parentIPFSname} to {artifactIPFSName}')
                data = {"nodeida": parentIPFSname, "nodeidb": artifactIPFSName}
                r = httpx.post(createRelationshipEndpoint, json=data)
                print(r.status_code)
                print(r.text)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Ingests the given hierarchical CSV file containing requirements and tests and uploads each item into an instance of ChaordicLedger.')
    parser.add_argument('-i', '--input',
                        help="The input CSV file.", required=True)
    parser.add_argument('--ledgerURL', required=True)

    args = parser.parse_args()

    tree = ingestHierarchy(args.input)
    uploadToLedger(tree, args.ledgerURL)

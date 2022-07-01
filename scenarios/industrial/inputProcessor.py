import argparse
import logging
import json
import os
import requests
from requests_toolbelt.multipart import encoder

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Processes the given inputs as part of a test scenario.')
    parser.add_argument('-i', '--inputdir',
                        help="The input directory.", required=True)

    args = parser.parse_args()

    inputMap = None

    with open(os.path.join(args.inputdir, "map.json"), 'r') as f:
        inputMap = json.load(f)

    apiRoot = "http://localhost:8080/v1"

    artifactUrl = f"{apiRoot}/artifacts/createArtifact"
    relationshipUrl = f"{apiRoot}/relationships/createRelationship"

    responseMap = {}

    for file in inputMap.keys():
        print(f"Uploading artifact \"{file}\" to {artifactUrl}.")

        session = requests.session()
        with open(os.path.join(args.inputdir, file), 'rb') as f:
            form = encoder.MultipartEncoder({
                "upfile": (file, f, "application/octet-stream"),
                "friendlyname": file
            })
            headers = {"Prefer": "respond-async",
                       "Content-Type": form.content_type}
            response = session.post(
                artifactUrl, headers=headers, data=form.to_string())
            print(f"Code: {response.status_code} - {response.text}")

            data = json.loads(response.text)["result"]
            print(data)

            responseMap[file] = data
        session.close()

        for relation in inputMap[file]:
            sourceName = responseMap[file]["IPFSName"]
            targetName = responseMap[relation]["IPFSName"]
            print(
                f"Submitting relationship between \"{file}\" (\"{sourceName}\") and \"{relation}\" (\"{targetName}\") to {relationshipUrl}.")

            response = requests.post(relationshipUrl, json={
                "nodeida": sourceName,
                "nodeidb": targetName
            })

            print(f"Code: {response.status_code} - {response.text}")

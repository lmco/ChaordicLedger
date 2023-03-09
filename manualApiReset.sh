#!/bin/bash
set -e

if [ -d "apiServer" ]; then
    echo "Removing API server directory."
    rm -rf apiServer
else
    echo "NOT removing API server directory. It does not exist."
fi

if [ -f nodejs-server.zip ]; then
    echo "Removing nodejs server archive."
    rm nodejs-server.zip
fi

#   Note: Ideally, this would be in an NPM registry, but an account doesn't yet exist for the lmco organization.
#   TODO: Once the org exists, look into NPM packaging at https://docs.github.com/en/actions/publishing-packages/publishing-nodejs-packages
. githubReadToken.sh
latestSuccessfulRun=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/lmco/chaordicledger/actions/runs?state=Success | jq '.workflow_runs[0].id')
zipDownloadUrl=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/lmco/chaordicledger/actions/runs/${latestSuccessfulRun}/artifacts | jq '.artifacts[] | select(.name=="nodejs-server")' | jq '.archive_download_url' | tr -d '\"')
curl -vvv -L -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${githubReadToken}" ${zipDownloadUrl} --output nodejs-server.zip

unzip nodejs-server.zip -d apiServer

cd apiServer
echo "Starting API server."
npm install connect
npm start

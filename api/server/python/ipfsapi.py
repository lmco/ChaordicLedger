import argparse
from datetime import datetime
import io
import os
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


def validateArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--ipfsapiserver", action="store",
                        help="The address of the IPFS API (e.g. /dns/localhost/tcp/5001/http)", required=False, default="/dns/ipfs-rpc-api/tcp/5001/http")
    parser.add_argument("-f", "--file", action="store",
                        help="The file to retrieve.", required=True)
    parser.add_argument("-o", "--outputdir", action="store",
                        help="The location for the retrieved file.", required=False, default="/tmp")

    args = parser.parse_args()

    client = ipfshttpclient.connect(args.ipfsapiserver)

    return (client, args.file, os.path.join(args.outputdir, args.file))


if __name__ == "__main__":
    starttime = datetime.utcnow()

    configureLogging()
    (client, file, outputFile) = validateArgs()

    log.info("Retrieving file: %s to %s", file, outputFile)

    response = client.files.read(file)
    with open(outputFile, "w") as f:
        f.write(response.decode())

    endtime = datetime.utcnow()
    log.info(
        "Done retrieving file. Execution completed in %s", endtime-starttime)

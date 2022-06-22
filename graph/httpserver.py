# Reference: https://pythonbasics.org/webserver/

import ipfshttpclient
import json
import io
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
import sys

hostName = "0.0.0.0"
serverPort = 5678
log = logging.getLogger(__name__)


def configureLogging():
    formatter = logging.Formatter('%(asctime)s | %(levelname)s | %(message)s',
                                  '%Y-%m-%dT%H:%M:%SZ')

    log.setLevel(logging.DEBUG)

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.DEBUG)
    stdout_handler.setFormatter(formatter)

    log.addHandler(stdout_handler)


class MyServer(BaseHTTPRequestHandler):
    def write_data(self, data):
        client = ipfshttpclient.connect("/dns/ipfs-ui/tcp/5001/http")
        jsonData = json.loads(data)
        graph = client.files.read(
            "/graph.json").decode('utf-8')
        log.info(graph)
        graphData = json.loads(graph)
        if len(jsonData) > 0 and "Type" in jsonData:
            # Need to identify type:
            datatype = jsonData["Type"]
            data = jsonData["Data"]
            skip = False
            if datatype == "node":
                log.info(f"Appending node: %s", data)
                graphData["nodes"].append(data)
            elif datatype == "relationship":
                log.info(f"Appending relationship: %s", data)
                graphData["relationships"].append(data)
            else:
                log.error("Unrecognized type: %s", datatype)
                skip = True

            if not skip:
                graphStr = json.dumps(graphData)
                log.info(f"Writing updated graph content: %s", graphStr)
                response = client.files.write(
                    "/graph.json", io.BytesIO(graphStr.encode('utf-8')), create=True, truncate=True)
                log.info(response)
        else:
            log.error("Unrecognized data, no type provided: %s", jsonData)

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_GET(self):
        self._set_headers()
        response = '{ "response" : "received GET request" }\n'
        self.wfile.write(response.encode())

    def do_POST(self):
        '''Reads post request body'''
        self._set_headers()
        content_len = int(self.headers.get('Content-Length'))
        log.info("Content Length %s", content_len)
        post_body_bin = self.rfile.read(content_len)
        log.info("Received %s", post_body_bin)
        post_body = post_body_bin.decode()
        log.info("Received %s", post_body)
        try:
            self.write_data(post_body)
            # output = subprocess.run(args=["python", "graphProcessor.py", "-i /dns/ipfs-ui/tcp/5001/http",
            #                               '-m "write"', "-n " + post_body, '-r "{}"'], shell=True)
            # log.info("Output: %s", output)
        except Exception as e:
            log.error(e)

        response = "{ " + f'"response" : {post_body}' + "}\n"
        self.wfile.write(response.encode())

    def do_PUT(self):
        log.info("Received a PUT, treating as a POST")
        self.do_POST()


if __name__ == "__main__":
    configureLogging()
    webServer = HTTPServer((hostName, serverPort), MyServer)
    log.info("Server started http://%s:%s", hostName, serverPort)

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    log.info("Server stopped.")

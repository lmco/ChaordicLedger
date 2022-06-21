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
    def write_node(self, node):
        client = ipfshttpclient.connect("/dns/ipfs-ui/tcp/5001/http")
        jsonNode = json.loads(node)
        data = client.files.read(
            "/graph.json").decode('utf-8')
        log.info(data)
        jsonData = json.loads(data)
        if len(jsonNode) > 0:
            log.info(f"Appending node: %s", node)
            jsonData["nodes"].append(jsonNode)

        jsonStr = json.dumps(jsonData)
        log.info(f"Writing updated graph content: %s", jsonStr)
        response = client.files.write(
            "/graph.json", io.BytesIO(jsonStr.encode('utf-8')), create=True, truncate=True)
        log.info(response)

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
            self.write_node(post_body)
            # output = subprocess.run(args=["python", "graphProcessor.py", "-i /dns/ipfs-ui/tcp/5001/http",
            #                               '-m "write"', "-n " + post_body, '-r "{}"'], shell=True)
            # log.info("Output: %s", output)
        except Exception as e:
            log.error(e)

        response = "{ " + f'"response" : {post_body}' + "}\n"
        self.wfile.write(response.encode())

    def do_PUT(self):
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

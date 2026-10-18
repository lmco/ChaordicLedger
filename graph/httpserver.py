# Reference: https://pythonbasics.org/webserver/

import ipfshttpclient
import json
import io
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
import sys

hostName = "0.0.0.0"
serverPort = 5678
maxBodyBytes = 1024 * 1024
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
    def parse_body(self, jsonData):
        if not isinstance(jsonData, dict) or "Type" not in jsonData:
            raise ValueError("Unrecognized data, no type provided")
        if "Data" not in jsonData:
            raise ValueError("No data provided")

        datatype = jsonData["Type"]
        data = jsonData["Data"]
        if datatype == "node":
            key = "nodes"
        elif datatype == "relationship":
            key = "edges"
        else:
            raise ValueError(f"Unrecognized type: {datatype}")
        return key, data

    def write_data(self, key, data):
        with ipfshttpclient.connect("/dns/ipfs-rpc-api/tcp/5001/http") as client:
            graph = client.files.read(
                "/graph.json").decode('utf-8')
            log.info(graph)
            graphData = json.loads(graph)

            log.info("Appending to %s: %s", key, data)
            graphData[key].append(data)

            graphStr = json.dumps(graphData)
            log.info("Writing updated graph content: %s", graphStr)
            response = client.files.write(
                "/graph.json", io.BytesIO(graphStr.encode('utf-8')), create=True, truncate=True)
            log.info(response)

    def _set_headers(self, status=200):
        self.send_response(status)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def _send_json(self, status, body):
        self._set_headers(status)
        self.wfile.write((json.dumps(body) + "\n").encode())

    def do_GET(self):
        self._send_json(200, {"response": "received GET request"})

    def do_POST(self):
        '''Reads post request body'''
        try:
            content_len = int(self.headers.get('Content-Length'))
            if content_len < 0:
                raise ValueError("negative Content-Length")
        except (TypeError, ValueError):
            self._send_json(411, {"error": "A valid Content-Length header is required"})
            return
        if content_len > maxBodyBytes:
            self._send_json(413, {"error": f"Request body exceeds {maxBodyBytes} bytes"})
            return
        log.info("Content Length %s", content_len)
        post_body = self.rfile.read(content_len)
        log.info("Received %s", post_body)

        try:
            jsonData = json.loads(post_body)
            key, data = self.parse_body(jsonData)
        except ValueError as e:
            # Includes JSONDecodeError and UnicodeDecodeError.
            log.error("Rejected request: %s", e)
            self._send_json(400, {"error": str(e)})
            return

        try:
            self.write_data(key, data)
        except Exception as e:
            log.exception("Failed to update graph")
            self._send_json(500, {"error": str(e)})
            return

        self._send_json(200, {"response": jsonData})

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

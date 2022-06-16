# Reference: https://pythonbasics.org/webserver/

import subprocess
import ipfshttpclient
import json
import io
from http.server import BaseHTTPRequestHandler, HTTPServer

hostName = "localhost"
serverPort = 7070


class MyServer(BaseHTTPRequestHandler):
    def write_node(self, node):
        client = ipfshttpclient.connect("/dns/ipfs-ui/tcp/5001/http")
        jsonNode = json.loads(node)
        jsonData = json.loads(client.files.read(
            "/graph.json").decode('utf-8)'))
        if len(jsonNode) > 0:
            print(f"Appending node: {node}")
            jsonData["nodes"].append(jsonNode)

        jsonStr = json.dumps(jsonData)
        print(f"Writing updated graph content: {jsonStr}")
        response = client.files.write(
            "/graph.json", io.BytesIO(jsonStr.encode('utf-8')), create=True, truncate=True)
        print(response)

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
        post_body = self.rfile.read(content_len).decode()
        print("Received %s" % post_body)
        try:
            self.write_node(post_body)
            # output = subprocess.run(args=["python", "graphProcessor.py", "-i /dns/ipfs-ui/tcp/5001/http",
            #                               '-m "write"', "-n " + post_body, '-r "{}"'], shell=True)
            # print("Output: %s" % output)
        except Exception as e:
            print("Failed to execute subprocess: " + e)

        response = "{ " + f'"response" : {post_body}' + "}\n"
        self.wfile.write(response.encode())

    def do_PUT(self):
        self.do_POST()


if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")

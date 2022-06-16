# Reference: https://pythonbasics.org/webserver/

from http.server import BaseHTTPRequestHandler, HTTPServer

hostName = "localhost"
serverPort = 7070


class MyServer(BaseHTTPRequestHandler):
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

import os
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"service":"payment-api","status":"HEALTHY","compliance":"PCI-DSS v4.0","candidate":"phani"}\n')

port = int(os.environ.get("PORT", 80))
server = HTTPServer(("0.0.0.0", port), Handler)
print(f"Payment API running on port {port}")
server.serve_forever()

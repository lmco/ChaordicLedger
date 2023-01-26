var writeText = exports.writeText = function (response, arg1) {
  var payload = arg1;
  var code = 200;
  response.writeHead(code, {
    'Content-Type': 'text/plain',
    'Content-Disposition': 'attachment; filename=file.txt'
  });
  response.end(payload);
}

var writeBinary = exports.writeBinary = function (response, code, payload, filename, payloadLength) {
  response.writeHead(code, {
    'Content-Type': 'application/octet-stream',
    'Content-Disposition': 'attachment;filename=' + filename,
    'Content-Length': payloadLength
  });
  response.end(payload);
}

exports.getRelationshipGraphFile = function() {
    const fs = require('fs')
    const stream = require('stream')

    const exec = require("child_process").exec;
    exec(`curl http://localhost/rpc/api/v0/files/read?arg=/graph.json -o /tmp/graph.json`, (error, stdout, stderr) => {
        if (error) {
          resolve({ "result": null, "error": stderr, "durationInNanoseconds": end - start })
        } else {
            const mystream = fs.createReadStream("/tmp/graph.json");

            const result = []
            const w = new stream.Writable({
                write(chunk, encoding, callback) {
                result.push(chunk)
                callback()
                }
            })
            mystream.pipe(w)
            return new Promise((resolve, reject) => {
                w.on('finish', resolve)
                w.on('error', reject)
            }).then(() => result.join(''))
        }
    });
  }

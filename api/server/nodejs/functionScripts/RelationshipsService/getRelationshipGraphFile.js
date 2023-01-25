exports.getRelationshipGraphFile = function() {
    const fs = require('fs')
    const stream = require('stream')

    const exec = require("child_process").exec;

    return new Promise((resolve, reject) => {
        exec(`touch /tmp/thegraph.json && export ipfsPodName=$(kubectl -n chaordicledger get pods | grep "ipfs-" | awk '{print $1;}') && export ipfsPodIp=$(kubectl -n chaordicledger get pod $ipfsPodName -o json | jq -r '.status.podIP') && export no_proxy=$ipfsPodIp && curl -X POST http://$ipfsPodIp:5001/api/v0/files/read?arg=/graph.json -o /tmp/thegraph.json`, (error, stdout, stderr) => {
            // if (error) {
            //   // resolve({ "result": null, "error": stderr, "durationInNanoseconds": end - start })
            //   return new Promise((resolve, reject) => {
            //     reject({ "result": null, "error": stderr, "durationInNanoseconds": end - start })
            //   })
            // } else {
            const mystream = fs.createReadStream("/tmp/thegraph.json");
            const result = []
            const w = new stream.Writable({
                write(chunk, encoding, callback) {
                result.push(chunk)
                callback()
            }
            })

            w.on('finish', resolve(result))
            w.on('error', reject)
            mystream.pipe(w)

            // return new Promise((resolve, reject) => {           
            //     w.on('finish', resolve)
            //     w.on('error', reject)
            //     mystream.pipe(w)
            // }).then(() => result.join(''))
            // }
        });
    }).then(() => result.join(''))
  }
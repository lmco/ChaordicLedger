exports.getArtifactFile = function (artifactID) {
  const fs = require('fs')
  const stream = require('stream')

  const exec = require("child_process").exec;

  const outFileName = '/tmp/' + artifactID

  return new Promise((resolve, reject) => {
    exec(`touch ${outFileName} && export ipfsPodName=$(kubectl -n chaordicledger get pods | grep "ipfs-" | awk '{print $1;}') && export ipfsPodIp=$(kubectl -n chaordicledger get pod $ipfsPodName -o json | jq -r '.status.podIP') && export no_proxy=$ipfsPodIp && curl -X POST http://$ipfsPodIp:5001/api/v0/files/cat?arg=${artifactID} -o ${outFileName}`, (error, stdout, stderr) => {
      if (error) {
        reject({ "result": null, "error": stderr, "durationInNanoseconds": end - start })
      } else {
        const myStream = fs.createReadStream(outFileName);
        const result = []
        const w = new stream.Writable({
          write(chunk, encoding, callback) {
            result.push(chunk)
            callback()
          }
        })

        w.on('finish', () => {
          console.log("Finished retrieving relationship graph!")
          resolve(result.join(''))
        })
        w.on('error', (src) => {
          console.log(src)
          reject(src)
        })

        myStream.pipe(w)
      }
    });
  })
}

exports.getArtifactFile = function (artifactID) {
  const fs = require('fs')
  const stream = require('stream')

  const exec = require("child_process").exec;

  const outFileName = '/tmp/' + artifactID

  return new Promise((resolve, reject) => {
    exec(`touch ${outFileName} && export ipfsPodName=$(kubectl -n chaordicledger get pods | grep "ipfs-" | awk '{print $1;}') && export ipfsPodIp=$(kubectl -n chaordicledger get pod $ipfsPodName -o json | jq -r '.status.podIP') && export no_proxy=$ipfsPodIp && curl -X POST http://$ipfsPodIp:5001/api/v0/cat?arg=${artifactID} -o ${outFileName}`, (error, stdout, stderr) => {
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
          console.log("Finished retrieving artifact!")
          var jsonObj = JSON.parse(result.join(''));
          var originalName=jsonObj["originalname"]
          console.log('Returning artifact ' + artifactID + ' (original name: ' + originalName + ').')
          var buf = Buffer.from(jsonObj["buffer"]["data"], "hex")
          resolve([200, buf, originalName, buf.length])
        })
        w.on('error', (src) => {
          console.log(src)
          var buf = Buffer.from("error")
          reject([400, buf, "error", buf.length])
        })

        myStream.pipe(w)
      }
    });
  })
}

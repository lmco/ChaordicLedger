exports.getReducedRelationshipGraph = function (artifactID, maxDepth) {
  const fs = require('fs')
  const stream = require('stream')

  const exec = require("child_process").exec;

  const srcFileName = "/graph.json"
  const outFileName = "/tmp/reducedChaordicLedgerRelationshipGraph.json"
  const prefix = "testReduce"

  return new Promise((resolve, reject) => {
    exec(`touch ${outFileName} && export ipfsPodName=$(kubectl -n chaordicledger get pods | grep "ipfs-" | awk '{print $1;}') && export ipfsPodIp=$(kubectl -n chaordicledger get pod $ipfsPodName -o json | jq -r '.status.podIP') && export no_proxy=$ipfsPodIp && curl -X POST http://$ipfsPodIp:5001/api/v0/files/read?arg=${srcFileName} -o ${outFileName} && python3 utils/digraphReducer.py -t ${prefix}_${artifactID} -p ${prefix} -o /tmp -r ${artifactID} -f ${outFileName} -d ${maxDepth}`, (error, stdout, stderr) => {
      if (error) {
        reject({ "result": null, "error": stderr, "durationInNanoseconds": end - start })
      } else {
        const myStream = fs.createReadStream("/tmp/" + prefix + "RelationshipDigraph.gv");
        const result = []
        const w = new stream.Writable({
          write(chunk, encoding, callback) {
            result.push(chunk)
            callback()
          }
        })

        w.on('finish', () => {
          console.log("Finished retrieving reduced relationship graph!")
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

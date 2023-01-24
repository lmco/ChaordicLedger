exports.getRelationshipGraph = function () {
    var start = now('nano')
    const exec = require("child_process").exec;
    return new Promise(function (resolve, reject) {
      exec(`cat ./service/getRelationshipGraph.sh | exec kubectl -n chaordicledger exec deploy/chaordicledger-ipfs -i -- /bin/sh`, (error, stdout, stderr) => {
        var end = now('nano')
        if (error) {
          resolve({ "result": null, "error": stderr, "durationInNanoseconds": end - start })
        } else {
          resolve(stdout)
        }
      });
    });
  }
  
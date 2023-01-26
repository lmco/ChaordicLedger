module.exports.getArtifactFile = function getArtifactFile(req, res, next) {
  var artifactID = req.swagger.params['artifactID'].value;
  Artifacts.getArtifactFile(artifactID)
    .then(function (response) {
      utils.writeBinary(res, response[0], response[1], response[2], response[3]);
    })
    .catch(function (response) {
      utils.writeBinary(res, response[0], response[1], response[2], response[3]);
    });
};

module.exports.getArtifactFile = function getArtifactFile(req, res, next) {
  var artifactID = req.swagger.params['artifactID'].value;
  Artifacts.getArtifactFile(artifactID)
    .then(function (response) {
      utils.writeBinary(res, response);
    })
    .catch(function (response) {
      utils.writeBinary(res, response);
    });
};

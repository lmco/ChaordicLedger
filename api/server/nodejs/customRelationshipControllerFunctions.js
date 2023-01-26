module.exports.getRelationshipGraphFile = function getRelationshipGraphFile(req, res, next) {
  Relationships.getRelationshipGraphFile()
    .then(function (response) {
      utils.writeText(res, response);
    })
    .catch(function (response) {
      utils.writeText(res, response);
    });
};

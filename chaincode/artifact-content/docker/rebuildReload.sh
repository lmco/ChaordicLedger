docker build . --build-arg http_proxy=proxy-zsgov.external.lmco.com:80 --build-arg https_proxy=proxy-zsgov.external.lmco.com:80 -t lmregistry.global.lmco.com/ext.ghcr.io/lmco/chaordicledger/content-chaincode:v0.0.0
kind load docker-image lmregistry.global.lmco.com/ext.ghcr.io/lmco/chaordicledger/content-chaincode:v0.0.0 --name chaordiccluster
kubectl -n chaordicledger delete -f /tmp/chaordicledger/chaincode/org1-peer1-cc-artifact-content.yaml
kubectl -n chaordicledger apply -f /tmp/chaordicledger/chaincode/org1-peer1-cc-artifact-content.yaml

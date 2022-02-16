#!/bin/sh

git clone https://github.com/marchinm/fabric-samples.git
cd fabric-samples/test-network-k8s/
./network kind
./network up
./network channel create
./network chaincode deploy
./network chaincode invoke '{"Args":["CreateAsset","1","blue","35","tom","1000"]}'
./network chaincode query '{"Args":["ReadAsset","1"]}'
./network rest-easy
./network down
./network unkind

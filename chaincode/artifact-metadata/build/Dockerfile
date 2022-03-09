# Reference: https://github.com/hyperledgendary/fabric-ccaas-asset-transfer-basic

ARG GO_VER=1.14.4
ARG ALPINE_VER=3.12
#ARG ALPINE_VER=3.15
#ARG CORE_CHAINCODE_ID_NAME=artifact-metadata

FROM golang:${GO_VER}-alpine${ALPINE_VER}
#FROM golang:alpine3.15

WORKDIR /go/src/github.com/chaordicledger/chaincode/artifact-metadata
COPY . .

COPY cachain/LMChain/* /usr/local/share/ca-certificates/

#RUN cat /usr/local/share/ca-certificates/* >> /etc/ssl/certs/ca-certificates.crt 
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/*
RUN update-ca-certificates
#RUN apk add --update --no-cache ca-certificates
RUN go get -d -v ./...
RUN go install -v ./...
#RUN go build -o artifactmetadata
#RUN ls -al

EXPOSE 9999
#CMD ["./artifactmetadata", "-peer.address", "0.0.0.0:7051"]
#
#CMD ["sleep", "1000000"]

# Expectation: Complaint about peer.address not being set; Actual: starting container process caused: exec: "artifact-metadata": executable file not found in $PATH: unknown
#CMD ["artifact-metadata"]

#CMD ["sleep", "1000000"]

# The executable is always named chaincode-external.
CMD ["chaincode-external"]

#CMD ["chaincode-external", "-peer.address $CORE_PEER_ADDRESS"]

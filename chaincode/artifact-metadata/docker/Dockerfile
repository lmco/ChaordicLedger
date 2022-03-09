# Reference: https://github.com/hyperledgendary/fabric-ccaas-asset-transfer-basic

ARG GO_VER=1.14.4
ARG ALPINE_VER=3.12

FROM golang:${GO_VER}-alpine${ALPINE_VER}

WORKDIR /go/src/github.com/chaordicledger/chaincode/artifact-metadata
COPY . .

# Note: All copy sources must be at or below the current directory.
COPY cachain/LMChain/* /usr/local/share/ca-certificates/

RUN rm -rf /var/cache/apk/* && rm -rf /tmp/*
RUN update-ca-certificates
RUN go mod vendor
RUN go get -d -v ./...
RUN go install -v ./...

EXPOSE 9999

# The executable is always named chaincode-external.
CMD ["chaincode-external"]

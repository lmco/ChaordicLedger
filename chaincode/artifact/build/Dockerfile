# Reference: https://github.com/hyperledgendary/fabric-ccaas-asset-transfer-basic

ARG GO_VER=1.14.4
ARG ALPINE_VER=3.15
ARG CORE_CHAINCODE_ID_NAME=artifactmetadata
ARG CORE_PEER_ADDRESS=0.0.0.0:30303

#FROM golang:${GO_VER}-alpine${ALPINE_VER}
FROM golang:alpine3.15

WORKDIR /go/src/github.com/chaordicledger/chaincode/artifactmetadata
COPY . .

COPY cachain/LMChain/* /usr/local/share/ca-certificates/

#RUN cat /usr/local/share/ca-certificates/* >> /etc/ssl/certs/ca-certificates.crt 
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/*
RUN update-ca-certificates
#RUN apk add --update --no-cache ca-certificates
RUN go get -d -v ./...
RUN go install -v ./...
RUN go build -o /artifactmetadata

EXPOSE 9999
CMD ["/artifactmetadata", "-h"]

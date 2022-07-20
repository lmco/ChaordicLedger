# Reference: https://github.com/hyperledgendary/fabric-ccaas-asset-transfer-basic

ARG GO_VER=1.18.4
ARG ALPINE_VER=3.15

FROM golang:${GO_VER}-alpine${ALPINE_VER}

LABEL org.opencontainers.image.authors="michael.f.marchini@lmco.com"
LABEL org.opencontainers.image.description="Chaincode package for interacting with artifact relationships within a ChaordicLedger channel."
LABEL org.opencontainers.image.revision="0.0.1"
LABEL org.opencontainers.image.source="https://github.com/lmco/ChaordicLedger"
LABEL org.opencontainers.image.title="artifact-relationship Chaincode for ChaordicLedger"
LABEL org.opencontainers.image.vendor="Lockheed Martin Corporation"
LABEL org.opencontainers.image.version="0.0.1"

WORKDIR /go/src/github.com/chaordicledger/chaincode/artifact-relationship
COPY . .

# Copy trusted CA certificates so the 'go' processing can perform its operations.
# This is generally only applicable if the docker build is behind a proxy server
# that's rewriting responses and including its own certificate.
#
# Note: All copy sources must be at or below the current directory.
RUN mkdir -p ./cachain
COPY cachain/* /usr/local/share/ca-certificates/

RUN rm -rf /var/cache/apk/* && \
  rm -rf /tmp/* && \
  update-ca-certificates && \
  go mod init github.com/chaordicledger/artifact-relationship/chaincode-external && \
  go mod vendor && \
  go mod tidy && \
  go get -d -v ./... && \
  go install -v ./...

EXPOSE 9999

# The executable is always named chaincode-external.
ENTRYPOINT [ "chaincode-external" ]

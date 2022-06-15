FROM python:3.11.0b3-slim-buster

LABEL org.opencontainers.image.authors="michael.f.marchini@lmco.com"
LABEL org.opencontainers.image.description="Processor for artifacts and their relationships."
LABEL org.opencontainers.image.revision="0.0.1"
LABEL org.opencontainers.image.source="https://github.com/lmco/ChaordicLedger"
LABEL org.opencontainers.image.title="Graph Processor for ChaordicLedger"
LABEL org.opencontainers.image.vendor="Lockheed Martin Corporation"
LABEL org.opencontainers.image.version="0.0.1"

WORKDIR /
COPY graphProcessor.py ./

ENV HTTP_PROXY=http://proxy-zsgov.external.lmco.com:80
ENV HTTPS_PROXY=http://proxy-zsgov.external.lmco.com:80
ENV IPFS_API_SERVER=/dns/ipfs-ui/tcp/12345/http
ENV MODE="init"
ENV NODE="{}"
ENV RELATIONSHIP="{}"

RUN pip install ipfshttpclient

ENTRYPOINT python ./graphProcessor.py -i /dns/ipfs-ui/tcp/5001/http -m "$MODE" -n "$NODE" -r "$RELATIONSHIP"

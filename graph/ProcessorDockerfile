FROM python:3.11.0b3-slim-buster

LABEL org.opencontainers.image.authors="michael.f.marchini@lmco.com"
LABEL org.opencontainers.image.description="Server for graph processing."
LABEL org.opencontainers.image.revision="0.0.1"
LABEL org.opencontainers.image.source="https://github.com/lmco/ChaordicLedger"
LABEL org.opencontainers.image.title="Server for Graph Processing in ChaordicLedger"
LABEL org.opencontainers.image.vendor="Lockheed Martin Corporation"
LABEL org.opencontainers.image.version="0.0.1"

WORKDIR /

COPY httpserver.py ./
COPY graphProcessor.py ./

ENV HTTP_PROXY=
ENV HTTPS_PROXY=

RUN pip install ipfshttpclient

EXPOSE 5678/tcp

CMD [ "python", "./httpserver.py" ]

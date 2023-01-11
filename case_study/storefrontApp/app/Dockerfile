FROM python:3.11.0b3-slim-bullseye AS builder

LABEL org.opencontainers.image.authors="michael.f.marchini@lmco.com"
LABEL org.opencontainers.image.description="Microservice for a case study of using ChaordicLedger during development."
LABEL org.opencontainers.image.revision="0.0.1"
LABEL org.opencontainers.image.source="https://github.com/lmco/ChaordicLedger"
LABEL org.opencontainers.image.title="Storefront for ficticious e-commerce site."
LABEL org.opencontainers.image.vendor="Lockheed Martin Corporation"
LABEL org.opencontainers.image.version="0.0.1"

RUN python3 -m pip --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org install flask

WORKDIR /app

ENV FLASK_DEBUG=1
ENV FLASK_APP=/app/storefront.py
ENV FLASK_RUN_PORT=50000

EXPOSE ${FLASK_RUN_PORT}

COPY *.py /app/
COPY *.json /app/

ENTRYPOINT [ "python3" ]
CMD ["storefront.py"]

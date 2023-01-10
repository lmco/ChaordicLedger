FROM python:3.11.0b3-slim-bullseye AS builder

ARG HTTP_PROXY=http://proxy-zsgov.external.lmco.com:80
ARG HTTPS_PROXY=http://proxy-zsgov.external.lmco.com:80
ARG http_proxy=http://proxy-zsgov.external.lmco.com:80
ARG https_proxy=http://proxy-zsgov.external.lmco.com:80

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

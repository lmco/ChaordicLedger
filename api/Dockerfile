# Reference: https://medium.com/wesionary-team/swagger-ui-on-docker-for-testing-rest-apis-5b3d5fcdee7

FROM swaggerapi/swagger-ui

LABEL org.opencontainers.image.authors="michael.f.marchini@lmco.com"
LABEL org.opencontainers.image.description="Swagger UI package for interacting with the ChaordicLedger's contents."
LABEL org.opencontainers.image.revision="0.0.1"
LABEL org.opencontainers.image.source="https://github.com/lmco/ChaordicLedger/tree/main/swagger/docker"
LABEL org.opencontainers.image.title="Swagger UI for ChaordicLedger"
LABEL org.opencontainers.image.vendor="Lockheed Martin Corporation"
LABEL org.opencontainers.image.version="0.0.1"

EXPOSE 8080

COPY ./swagger.json ./

ENV SWAGGER_JSON=/swagger.json

CMD [ "/usr/share/nginx/run.sh" ]
ENTRYPOINT [ "./docker-entrypoint.sh" ]

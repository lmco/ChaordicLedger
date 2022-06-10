# Reference: https://github.com/hyperledgendary/fabric-ccaas-asset-transfer-basic

# the first stage 
#FROM gradle:6.3.0-jdk11 AS GRADLE_BUILD

# # copy the build.gradle and src code to the container
# COPY src/ src/
# COPY build.gradle ./ 
# COPY settings.gradle ./ 

# # Build and package our code
# #RUN gradle --no-daemon build shadowJar -x checkstyleMain -x checkstyleTest
# #RUN gradle --no-daemon -Dhttp.proxyHost=proxy-zsgov.external.lmco.com -Dhttp.proxyPort=80 -Dhttps.proxyHost=proxy-zsgov.external.lmco.com -Dhttps.proxyPort=80 build shadowJar -x checkstyleMain -x checkstyleTest
# RUN gradle --no-daemon -Dhttp.proxyHost=proxy-zsgov.external.lmco.com -Dhttp.proxyPort=80 -Dhttps.proxyHost=proxy-zsgov.external.lmco.com -Dhttps.proxyPort=80 build 
# #shadowJar

# the second stage of our build just needs the compiled files
FROM openjdk:11-jre

LABEL org.opencontainers.image.authors="michael.f.marchini@lmco.com"
LABEL org.opencontainers.image.description="Chaincode package for interacting with an Obsidian-defined lightswitch within a ChaordicLedger channel."
LABEL org.opencontainers.image.revision="0.0.1"
LABEL org.opencontainers.image.source="https://github.com/lmco/ChaordicLedger"
LABEL org.opencontainers.image.title="Obsidian Lightswitch Chaincode for ChaordicLedger"
LABEL org.opencontainers.image.vendor="Lockheed Martin Corporation"
LABEL org.opencontainers.image.version="0.0.1"

ARG CHAINCODE_ID=lightswitch
ARG PEER_ADDRESS=org1-peer1:7053
ARG CC_SERVER_PORT=9999

# Setup tini to work better handle signals
# ENV TINI_VERSION v0.19.0
# ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
# RUN chmod +x /tini

RUN addgroup --system javauser && useradd -g javauser javauser

# copy only the artifacts we need from the first stage and discard the rest
COPY build/libs/chaincode.jar /chaincode.jar
COPY logging.properties /logging.properties
#COPY --chown=javauser:javauser --from=GRADLE_BUILD /home/gradle/build/libs/chaincode.jar /chaincode.jar
COPY --chown=javauser:javauser docker/docker-entrypoint.sh /docker-entrypoint.sh 
RUN chmod +x /docker-entrypoint.sh

ENV PORT $CC_SERVER_PORT

EXPOSE $CC_SERVER_PORT

USER javauser

ENV CORE_CHAINCODE_ID_NAME $CHAINCODE_ID
ENV CORE_PEER_ADDRESS $PEER_ADDRESS
ENV CORE_PEER_TLS_ENABLED "false"
ENV CORE_PEER_TLS_CERT_FILE /var/hyperledger/fabric/config/tls/tls.crt
ENV CORE_PEER_TLS_KEY_FILE /var/hyperledger/fabric/config/tls/tls.key
ENV CORE_PEER_TLS_ROOTCERT_FILE /var/hyperledger/fabric/config/tls/ca.crt
ENV CORE_PEER_ID org1-peer1.org1.example.com
ENV CORE_PEER_ADDRESS org1-peer1:7053
ENV CORE_CHAINCODE_LOGGING_LEVEL DEBUG
ENV CORE_CHAINCODE_LOGGING_SHIM DEBUG
#ENTRYPOINT [ "/tini", "--", "/docker-entrypoint.sh" ]
ENTRYPOINT [ "/docker-entrypoint.sh" ]

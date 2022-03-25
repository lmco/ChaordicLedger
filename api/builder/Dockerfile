# Reference: https://stackoverflow.com/questions/58626842/illegal-option-cacerts-for-keytool-in-gitlab-ci-with-gradlejdk8

# The code generated from Swagger requires Gradle 6.
FROM gradle:6.8.2

LABEL org.opencontainers.image.authors="michael.f.marchini@lmco.com"
LABEL org.opencontainers.image.description="Custom Gradle image for building behind a corporate firewall."
LABEL org.opencontainers.image.revision="0.0.1"
LABEL org.opencontainers.image.source="https://github.com/lmco/ChaordicLedger"
LABEL org.opencontainers.image.title="Swagger API Builder for ChaordicLedger"
LABEL org.opencontainers.image.vendor="Lockheed Martin Corporation"
LABEL org.opencontainers.image.version="0.0.1"

# Updating the certs and keystore is necessary for building behind corporate firewalls.
RUN mkdir -p ./cachain
COPY cachain/* /usr/local/share/ca-certificates/

RUN rm -rf /var/cache/apk/* && \
  rm -rf /tmp/* && \
  update-ca-certificates

RUN count=$(ls /usr/local/share/ca-certificates/ | grep .crt | wc -l) && \
  echo "Certificate count: ${count}" && \
  i=0 && \
  cd /usr/local/share/ca-certificates/ && \
  for file in *.crt; do i=$((i+1));echo "Adding \"$file\" to keystore" && keytool -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt -trustcacerts -importcert -alias root${i} -file "$file"; done || true

# Note: the use of '-keystore $JAVA_HOME/jre/lib/security/cacerts' is aliased to the flag '-cacerts' in later versions of keytool.

ARG UPSTREAM_VERSION=0.4.0
ARG MIRROR=https://archive.apache.org/dist

# build phase
FROM alpine:3.9 as build
LABEL stage=build
ARG UPSTREAM_VERSION
ARG MIRROR

ENV PROJECT_BASE_DIR /opt/nifi-registry
ENV PROJECT_HOME ${PROJECT_BASE_DIR}/nifi-registry-${UPSTREAM_VERSION}

ENV UPSTREAM_BINARY_URL nifi/nifi-registry/nifi-registry-${UPSTREAM_VERSION}/nifi-registry-${UPSTREAM_VERSION}-bin.tar.gz
ENV DOCKERIZE_VERSION v0.6.1

RUN apk --update add --no-cache \
  &&   apk add --no-cache ca-certificates openssl curl wget \
  &&   update-ca-certificates \
  &&   rm -rf /var/lib/apt/lists/* \
  &&   rm -f /var/cache/apk/*

# Download, validate, and expand Apache NiFi-Registry binary.
RUN mkdir -p ${PROJECT_BASE_DIR} \
    && curl -fSL ${MIRROR}/${UPSTREAM_BINARY_URL} -o ${PROJECT_BASE_DIR}/nifi-registry-${UPSTREAM_VERSION}-bin.tar.gz \
    && echo "$(curl ${MIRROR}/${UPSTREAM_BINARY_URL}.sha256) *${PROJECT_BASE_DIR}/nifi-registry-${UPSTREAM_VERSION}-bin.tar.gz" | sha256sum -c - \
    && tar -xvzf ${PROJECT_BASE_DIR}/nifi-registry-${UPSTREAM_VERSION}-bin.tar.gz -C ${PROJECT_BASE_DIR} \
    && rm ${PROJECT_BASE_DIR}/nifi-registry-${UPSTREAM_VERSION}-bin.tar.gz \
    && rm -fr ${PROJECT_HOME}/docs

RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# final phase
FROM openjdk:8-jdk-alpine as final-root
ARG BRANCH
ARG COMMIT
ARG DATE
ARG URL
ARG VERSION
LABEL \
    site="https://hub.docker.com/r/michalklempa/nifi-registry" \
    maintainer="michal.klempa@gmail.com" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$DATE \
    org.label-schema.vendor="Michal Klempa" \
    org.label-schema.name="michalklempa/nifi-registry" \
    org.label-schema.description="michalklempa/nifi-registry docker image is an alternative and unofficial image for NiFi Registry project" \
    org.label-schema.url="https://hub.docker.com/r/michalklempa/nifi-registry" \
    org.label-schema.docker.cmd="docker run -p 18080:18080 --name nifi-registry -d michalklempa/nifi-registry:latest" \
    org.label-schema.docker.cmd.devel="docker run -p 8000:8000 -p 18080:18080 -e'BOOTSTRAP_JAVA_ARG_DEBUG=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000' --name nifi-registry -d michalklempa/nifi-registry:latest" \
    org.label-schema.version="$VERSION" \
    org.label-schema.vcs-url=$URL \
    org.label-schema.vcs-branch=$BRANCH \
    org.label-schema.vcs-ref=$COMMIT

ARG UPSTREAM_VERSION

ENV PROJECT_BASE_DIR /opt/nifi-registry
ENV PROJECT_HOME ${PROJECT_BASE_DIR}/nifi-registry-${UPSTREAM_VERSION}

ENV PROJECT_TEMPLATE_DIR ${PROJECT_BASE_DIR}/templates

ENV PROJECT_CONF_DIR ${PROJECT_HOME}/conf

RUN apk --update add --no-cache ca-certificates bash git less openssh sshpass \
  && update-ca-certificates \
  &&   rm -rf /var/lib/apt/lists/* \
  &&   rm -f /var/cache/apk/*

# Setup NiFi-Registry user
RUN mkdir -p ${PROJECT_BASE_DIR}

COPY --from=build ${PROJECT_HOME} ${PROJECT_HOME}
COPY --from=build /usr/local/bin/dockerize /usr/local/bin/dockerize
COPY ./templates ${PROJECT_TEMPLATE_DIR}

COPY sh/ ${PROJECT_BASE_DIR}/scripts/

RUN mkdir -p ${PROJECT_HOME}/docs

# Web HTTP(s) ports
EXPOSE 18080 18443

ENV FLOW_PROVIDER file
ENV FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY $PROJECT_BASE_DIR/flow-storage
ENV FLOW_PROVIDER_FILE_FLOW_STORAGE_DIRECTORY $PROJECT_BASE_DIR/flow-storage

ENV EXTENSION_BUNDLE_PROVIDER file
ENV EXTENSION_BUNDLE_PROVIDER_FILE_EXTENSION_BUNDLE_STORAGE_DIRECTORY $PROJECT_BASE_DIR/extension-bundle-storage

WORKDIR ${PROJECT_HOME}

# Apply configuration and start NiFi Registry
CMD ${PROJECT_BASE_DIR}/scripts/start.sh


<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# Unofficial Docker Image For NiFi Registry

This README.md is trimmed by hub.docker.com. Full version:

# See [http://github.com/michalklempa/docker-nifi-registry/](http://github.com/michalklempa/docker-nifi-registry/)

## Project home
 - Image: [https://hub.docker.com/r/michalklempa/nifi-registry](https://hub.docker.com/r/michalklempa/nifi-registry)
-  Source code: [http://github.com/michalklempa/docker-nifi-registry/](http://github.com/michalklempa/docker-nifi-registry/)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Notice](#notice)
- [Capabilities](#capabilities)
- [Environment variables templating into nifi-registry.properties](#environment-variables-templating-into-nifi-registryproperties)
- [Templating conditions](#templating-conditions)
- [Running and configuring a container](#running-and-configuring-a-container)
  - [Standalone Instance, Unsecured](#standalone-instance-unsecured)
  - [Java Heap Options and other properties in bootstrap.conf](#java-heap-options-and-other-properties-in-bootstrapconf)
  - [Standalone Instance, Java Remote Debug](#standalone-instance-java-remote-debug)
  - [NiFi Registry Listen Properties](#nifi-registry-listen-properties)
  - [Standalone Instance, Two-Way SSL](#standalone-instance-two-way-ssl)
    - [nifi-registry.properties](#nifi-registryproperties)
    - [authorizers.xml](#authorizersxml)
  - [Standalone Instance, LDAP](#standalone-instance-ldap)
    - [nifi-registry.properties](#nifi-registryproperties-1)
    - [identity-providers.xml](#identity-providersxml)
  - [Standalone Instance, Kerberos](#standalone-instance-kerberos)
    - [nifi-registry.properties](#nifi-registryproperties-2)
    - [identity-providers.xml](#identity-providersxml-1)
- [Database configuration](#database-configuration)
- [Flow persistence provider configuration](#flow-persistence-provider-configuration)
  - [FileSystemFlowPersistenceProvider (default)](#filesystemflowpersistenceprovider-default)
  - [GitFlowPersistenceProvider](#gitflowpersistenceprovider)
  - [DatabaseFlowPersistenceProvider](#databaseflowpersistenceprovider)
- [Git cloning the repository at startup](#git-cloning-the-repository-at-startup)
  - [Git user.name and user.email](#git-username-and-useremail)
  - [Cloning using HTTPS](#cloning-using-https)
  - [Cloning using GIT+SSH](#cloning-using-gitssh)
    - [SSH keys using environemnt variables](#ssh-keys-using-environemnt-variables)
    - [SSH keys using mount point](#ssh-keys-using-mount-point)
- [Bundle Persistence Providers configuration](#bundle-persistence-providers-configuration)
  - [FileSystemBundlePersistenceProvider (default)](#filesystembundlepersistenceprovider-default)
  - [S3BundlePersistenceProvider](#s3bundlepersistenceprovider)
- [Providing configuration by mounting files](#providing-configuration-by-mounting-files)
- [Running under different UID:GID](#running-under-different-uidgid)
  - [Running as root](#running-as-root)
  - [Running as custom UID:GID](#running-as-custom-uidgid)
- [Building](#building)
- [Contributing](#contributing)
- [Building Release Candindates](#building-release-candindates)
- [Building 1.0.0-SNAPSHOT](#building-100-snapshot)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Notice
This image is inspired by the official image: [apache/nifi-registry](https://hub.docker.com/r/apache/nifi-registry).
The configuration capabilities and options are taken from that image (see the copyright [NOTICE](NOTICE) and [LICENSE](LICENSE)).

The way the image is configured at runtime is reworked to use [Go templates](https://golang.org/pkg/text/template/)
and the runtime fork & logs capture is handled by [dockerize](https://github.com/jwilder/dockerize).

Image is based on [openjdk:8-jdk-alpine](https://hub.docker.com/_/openjdk).
It is also smaller than the official one (251MB vs. 387MB).

The dockerhub hook scripts are attributed to [jnovack/dockerhub-hooks](https://github.com/jnovack/dockerhub-hooks).

The configuration environment variables are different, so this image is not a drop-in replacement for the official one. Read the documentation below. We have included the original
names in this readme for the convenience, but these are **NOT** supported by this image. Update your launch scripts accordingly.

## Capabilities
This image currently supports running in standalone mode either unsecured or with user authentication provided through:
   * [Two-Way SSL with Client Certificates](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#security-configuration)
   * [Lightweight Directory Access Protocol (LDAP)](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#ldap_identity_provider)
   * [Kerberos](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#kerberos_identity_provider)

## Environment variables templating into nifi-registry.properties
All environment variables are templated into `conf/nifi-registry.properties` values
using this naming scheme:
 1. use only environment variables starting with prefix `NIFI_REGISTRY`
 2. swap case of every character (e.g. `NIFI_REGISTRY_cAMELcASE` becomes `nifi_registry_CamelCase`)
 3. replace all `_` (underscores) with `.` (dots) (e.g. `nifi_registry_CamelCase` becomes `nifi.registry.CamelCase`)

Some examples:

| nifi-registry.properties property       | Environment variable                    |
|-----------------------------------------|-----------------------------------------|
| NIFI_REGISTRY_SECURITY_TRUSTSTOREpASSWD | nifi.registry.security.truststorePasswd |
| NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH   | nifi.registry.security.needClientAuth   |


This way, you can set and change any property in `nifi-registry.properties`.
Do not name your own environment variables with prefix `NIFI_REGISTRY`, they will get templated into the properties file.

Image provides additional environmental variables to configure `authorizers.xml`, `identity-providers.xml` and `providers.xml`.
These are described below.

##  Templating conditions
1. `nifi-registry.properties` is templated from environmental variables iff any variable named NIFI_REGISTRY* is set
3. `authorizers.xml` is templated iff `INITIAL_ADMIN_IDENTITY` is set
4. `identity-providers.xml` is templated iff `NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER` is set
5. `providers.xml` is templated iff `FLOW_PROVIDER` is set (this is always set by default, you have to set it to empty string). e.g. `-e 'FLOW_PROVIDER='`, see
   https://github.com/michalklempa/docker-nifi-registry/issues/20).
6. `bootstrap.conf` is templated iff any variable named BOOTSTRAP_* is set

## Running and configuring a container
### Standalone Instance, Unsecured
The minimum to run a NiFi Registry instance is as follows (compose: [docker-compose.simple.yml](docker-compose.simple.yml)):
```
    docker run --name nifi-registry \
      -p 18080:18080 \
      -d \
      michalklempa/nifi-registry:latest
```
This will provide a running instance, exposing the instance UI to the host system on at port 18080,
viewable at `http://localhost:18080/nifi-registry`.

You can also pass in environment variables to change the NiFi Registry communication ports and hostname using the Docker `-e` switch as follows:
```
    docker run --name nifi-registry \
      -p 19090:19090 \
      -e 'NIFI_REGISTRY_WEB_HTTP_PORT=19090' \
      -d \
      michalklempa/nifi-registry:latest
```
Unless you specify `NIFI_REGISTRY_WEB_HTTP_HOST`, NiFi Registry will bind to IP address `0.0.0.0`,
thus listening on all available interfaces. This is different from official image - where the result of shell expression
`$(hostname)` is supplied into `nifi.registry.web.http.host` property by default.

### Java Heap Options and other properties in bootstrap.conf

To increase Java Heap Size or tune any other property in `bootstrap.conf` use environment
variables prefixed with `BOOTSTRAP_`.
```
    docker run --name nifi-registry \
      -p 18080:18080 \
      -e 'BOOTSTRAP_JAVA_ARG_2=-Xms5012m' \
      -e 'BOOTSTRAP_JAVA_ARG_3=-Xmx15512m' \
      -d \
      michalklempa/nifi-registry:latest
```
For details, read the [templates/bootstrap.conf.gotemplate](templates/bootstrap.conf.gotemplate) file.

### Standalone Instance, Java Remote Debug
To attach your IDE for Java Remote Debugging, run:
```
    docker run --name nifi-registry \
      -p 8000:8000 \
      -p 18080:18080 \
      -e'BOOTSTRAP_JAVA_ARG_DEBUG=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8000' \
      -d \
      michalklempa/nifi-registry:latest
```

### NiFi Registry Listen Properties

| nifi-registry.properties property | Environment variable         | Official image variable      | Default Value | Description                                                                                                               |
|-----------------------------------|------------------------------|------------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------|
| nifi.registry.web.http.host       | NIFI_REGISTRY_WEB_HTTP_HOST  | NIFI_REGISTRY_WEB_HTTP_HOST  | (empty)       | Host to bind, can be IP address or hostname. Default empty value causes listening on all interfaces                       |
| nifi.registry.web.http.port       | NIFI_REGISTRY_WEB_HTTP_PORT  | NIFI_REGISTRY_WEB_HTTP_PORT  | 18080         | TCP Port to listen                                                                                                        |
| nifi.registry.web.https.host      | NIFI_REGISTRY_WEB_HTTPS_HOST | NIFI_REGISTRY_WEB_HTTPS_HOST | (empty)       | Host to bind for HTTPS connections, can be IP address or hostname. Default empty value causes listening on all interfaces |
| nifi.registry.web.https.port      | NIFI_REGISTRY_WEB_HTTPS_PORT | NIFI_REGISTRY_WEB_HTTPS_PORT | (empty)       | TCP Port to listen. Default empty, but value `18443` seems to be NiFi Registry standard                                   |

You may want to consult [Web Properties](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#web-properties) section of [Apache NiFi Registry System Administrator’s Guide](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html)

### Standalone Instance, Two-Way SSL
In this configuration, the user will need to provide certificates and the associated configuration information.
The user must provide the DN as provided by an accessing client certificate in the `INITIAL_ADMIN_IDENTITY` environment variable.
This value will be used to seed the instance with an initial user with administrative privileges.
Finally, this command makes use of a volume to provide certificates on the host system to the container instance.
This example as compose: [docker-compose.twowayssl.yml](docker-compose.twowayssl.yml)
```
    docker run --name nifi-registry \
      -v /path/to/tls/certs/localhost:/opt/certs \
      -p 18443:18443 \
      -e 'NIFI_REGISTRY_SECURITY_KEYSTORE=/opt/certs/keystore.jks' \
      -e 'NIFI_REGISTRY_SECURITY_KEYSTOREtYPE=JKS' \
      -e 'NIFI_REGISTRY_SECURITY_KEYSTOREpASSWD=QKZv1hSWAFQYZ+WU1jjF5ank+l4igeOfQRp+OSbkkrs' \
      -e 'NIFI_REGISTRY_SECURITY_TRUSTSTORE=/opt/certs/truststore.jks' \
      -e 'NIFI_REGISTRY_SECURITY_TRUSTSTOREtYPE=JKS' \
      -e 'NIFI_REGISTRY_SECURITY_TRUSTSTOREpASSWD=rHkWR1gDNW3R9hgbeRsT3OM3Ue0zwGtQqcFKJD2EXWE' \
      -e 'NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH=true' \
      -e 'NIFI_REGISTRY_WEB_HTTP_HOST=' \
      -e 'NIFI_REGISTRY_WEB_HTTP_PORT=' \
      -e 'NIFI_REGISTRY_WEB_HTTPS_HOST=0.0.0.0' \
      -e 'NIFI_REGISTRY_WEB_HTTPS_PORT=18443' \
      -e 'INITIAL_ADMIN_IDENTITY=CN=AdminUser, OU=nifi' \
      -d \
      michalklempa/nifi-registry:latest
```

See [Security Properties](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#security-properties) section of [Apache NiFi Registry System Administrator’s Guide](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html)

Let us summarize the properties set:

#### nifi-registry.properties

| nifi-registry.properties property       | Environment variable                    | Official image variable | Default Value                                                           | Description                                                                                                                                                                                                                                                                                                |
|-----------------------------------------|-----------------------------------------|-------------------------|-------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| nifi.registry.security.keystore         | NIFI_REGISTRY_SECURITY_KEYSTORE         | ~~KEYSTORE_PATH~~       | (empty)                                                                 | Filename of the Keystore that contains the server’s private key.                                                                                                                                                                                                                                           |
| nifi.registry.security.keystoreType     | NIFI_REGISTRY_SECURITY_KEYSTOREtYPE     | ~~KEYSTORE_TYPE~~       | (empty)                                                                 | The type of Keystore. Must be either PKCS12 or JKS. JKS is the preferred type, PKCS12 files will be loaded with BouncyCastle provider.                                                                                                                                                                     |
| nifi.registry.security.keystorePasswd   | NIFI_REGISTRY_SECURITY_KEYSTOREpASSWD   | ~~KEYSTORE_PASSWORD~~   | (empty)                                                                 | The password for the Keystore.                                                                                                                                                                                                                                                                             |
| nifi.registry.security.truststore       | NIFI_REGISTRY_SECURITY_TRUSTSTORE       | ~~TRUSTSTORE_PATH~~     | (empty)                                                                 | Filename of the Truststore that will be used to authorize those connecting to NiFi Registry. A secured instance with no Truststore will refuse all incoming connections.                                                                                                                                   |
| nifi.registry.security.truststoreType   | NIFI_REGISTRY_SECURITY_TRUSTSTOREtYPE   | ~~TRUSTSTORE_PASSWORD~~ | (empty)                                                                 | The type of the Truststore. Must be either PKCS12 or JKS. JKS is the preferred type, PKCS12 files will be loaded with BouncyCastle provider.                                                                                                                                                               |
| nifi.registry.security.truststorePasswd | NIFI_REGISTRY_SECURITY_TRUSTSTOREpASSWD | ~~TRUSTSTORE_TYPE~~     | (empty)                                                                 | The password for the Truststore.                                                                                                                                                                                                                                                                           |
| nifi.registry.security.needClientAuth   | NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH   | (no variable)           | empty in configuration file, NiFi documentation states default is true. | This specifies that connecting clients must authenticate with a client cert. Setting this to false will specify that connecting clients may optionally authenticate with a client cert, but may also login with a username and password against a configured identity provider. The default value is true. |

#### authorizers.xml

| authorizers.xml property                                                   | Environment variable   | Official image variable | Default Value | Description                                                                                                                                                                                                                                                                                                                                              |
|----------------------------------------------------------------------------|------------------------|-------------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| authorizers/userGroupProvider/property\[name='Initial User Identity 1'\]   | INITIAL_ADMIN_IDENTITY | INITIAL_ADMIN_IDENTITY  | (empty)       | The identity of a user or system to seed an empty Users File. Multiple Initial User Identity properties can be specified, but the name of each property must be unique, for example: "Initial User Identity A", "Initial User Identity B", "Initial User Identity C" or "Initial User Identity 1", "Initial User Identity 2", "Initial User Identity 3". |
| authorizers/accessPolicyProvider/property\[name='Initial Admin Identity'\] | INITIAL_ADMIN_IDENTITY | INITIAL_ADMIN_IDENTITY  | (empty)       | The identity of an initial admin user that will be granted access to the UI and given the ability to create additional users, groups, and policies. For example, a certificate DN, LDAP identity, or Kerberos principal.                                                                                                                                 |

### Standalone Instance, LDAP
In this configuration, the user will need to provide certificates and the associated configuration information.  Optionally,
if the LDAP provider of interest is operating in LDAPS or START_TLS modes, certificates will additionally be needed.
The user must provide a DN as provided by the configured LDAP server in the `INITIAL_ADMIN_IDENTITY` environment variable.
This value will be used to seed the instance with an initial user with administrative privileges.
Finally, this command makes use of a volume to provide certificates on the host system to the container instance.
This example as compose: [docker-compose.ldap.yml](docker-compose.ldap.yml)

For a minimal, connection to an LDAP server using SIMPLE authentication:
```
    docker run --name nifi-registry \
      -v /path/to/tls/certs/localhost:/opt/certs \
      -p 18443:18443 \
      -e 'NIFI_REGISTRY_SECURITY_KEYSTORE=/opt/certs/keystore.jks' \
      -e 'NIFI_REGISTRY_SECURITY_KEYSTOREtYPE=JKS' \
      -e 'NIFI_REGISTRY_SECURITY_KEYSTOREpASSWD=QKZv1hSWAFQYZ+WU1jjF5ank+l4igeOfQRp+OSbkkrs' \
      -e 'NIFI_REGISTRY_SECURITY_TRUSTSTORE=/opt/certs/truststore.jks' \
      -e 'NIFI_REGISTRY_SECURITY_TRUSTSTOREtYPE=JKS' \
      -e 'NIFI_REGISTRY_SECURITY_TRUSTSTOREpASSWD=rHkWR1gDNW3R9hgbeRsT3OM3Ue0zwGtQqcFKJD2EXWE' \
      -e 'NIFI_REGISTRY_WEB_HTTP_HOST=' \
      -e 'NIFI_REGISTRY_WEB_HTTP_PORT=' \
      -e 'NIFI_REGISTRY_WEB_HTTPS_HOST=0.0.0.0' \
      -e 'NIFI_REGISTRY_WEB_HTTPS_PORT=18443' \
      -e 'INITIAL_ADMIN_IDENTITY=cn=nifi-admin,dc=example,dc=org' \
      -e 'NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER=ldap-identity-provider' \
      -e 'NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH=false' \
      -e 'LDAP_AUTHENTICATION_STRATEGY=SIMPLE' \
      -e 'LDAP_MANAGER_DN=cn=ldap-admin,dc=example,dc=org' \
      -e 'LDAP_MANAGER_PASSWORD=password' \
      -e 'LDAP_USER_SEARCH_BASE=dc=example,dc=org' \
      -e 'LDAP_USER_SEARCH_FILTER=cn={0}' \
      -e 'LDAP_IDENTITY_STRATEGY=USE_DN' \
      -e 'LDAP_URL=ldap://ldap:389' \
      -d \
      michalklempa/nifi-registry:latest
```

Security properties are set as described at
[Lightweight Directory Access Protocol (LDAP)](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#ldap_login_identity_provider) section of [NiFi System Administrator’s Guide](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html) and [Security Properties](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#security-properties) section of [Apache NiFi Registry System Administrator’s Guide](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html)

Specifically two properties are set:

#### nifi-registry.properties

| nifi-registry.properties property          | Environment variable                     | Provided Value         | Description                                                                                                                                                                                                                                                                                                |
|--------------------------------------------|------------------------------------------|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| nifi.security.user.login.identity.provider | NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER | ldap-identity-provider | This indicates what type of login identity provider to use. The default value is blank, can be set to the identifier from a provider in the file specified in nifi.login.identity.provider.configuration.file. Setting this property will trigger NiFi to support username/password authentication.        |
| nifi.registry.security.needClientAuth      | NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH    | false                  | This specifies that connecting clients must authenticate with a client cert. Setting this to false will specify that connecting clients may optionally authenticate with a client cert, but may also login with a username and password against a configured identity provider. The default value is true. |

LDAP environment variables are rendered into `conf/identity-providers.xml` file as follows:

#### identity-providers.xml
| identity-providers.xml property | Environment variable           | Official image variable      | Default Value | Description                                                                                                                                                                                                                                                                                                |
|---------------------------------|--------------------------------|------------------------------|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Authentication Strategy         | LDAP_AUTHENTICATION_STRATEGY   | LDAP_AUTHENTICATION_STRATEGY | SIMPLE        | How the connection to the LDAP server is authenticated. Possible values are ANONYMOUS, SIMPLE, LDAPS, or START_TLS.                                                                                                                                                                                        |
| Manager DN                      | LDAP_MANAGER_DN                | LDAP_MANAGER_DN              | (empty)       | The DN of the manager that is used to bind to the LDAP server to search for users.                                                                                                                                                                                                                         |
| Manager Password                | LDAP_MANAGER_PASSWORD          | LDAP_MANAGER_PASSWORD        | (empty)       | The password of the manager that is used to bind to the LDAP server to search for users.                                                                                                                                                                                                                   |
| TLS - Keystore                  | LDAP_TLS_KEYSTORE              | LDAP_TLS_KEYSTORE            | (empty)       | Path to the Keystore that is used when connecting to LDAP using LDAPS or START_TLS.                                                                                                                                                                                                                        |
| TLS - Keystore Password         | LDAP_TLS_KEYSTORE_PASSWORD     | LDAP_TLS_KEYSTORE_PASSWORD   | (empty)       | Password for the Keystore that is used when connecting to LDAP using LDAPS or START_TLS.                                                                                                                                                                                                                   |
| TLS - Keystore Type             | LDAP_TLS_KEYSTORE_TYPE         | LDAP_TLS_KEYSTORE_TYPE       | (empty)       | Type of the Keystore that is used when connecting to LDAP using LDAPS or START_TLS (i.e. JKS or PKCS12).                                                                                                                                                                                                   |
| TLS - Truststore                | LDAP_TLS_TRUSTSTORE            | LDAP_TLS_TRUSTSTORE          | (empty)       | Path to the Truststore that is used when connecting to LDAP using LDAPS or START_TLS.                                                                                                                                                                                                                      |
| TLS - Truststore Password       | LDAP_TLS_TRUSTSTORE_PASSWORD   | LDAP_TLS_TRUSTSTORE_PASSWORD | (empty)       | Password for the Truststore that is used when connecting to LDAP using LDAPS or START_TLS.                                                                                                                                                                                                                 |
| TLS - Truststore Type           | LDAP_TLS_TRUSTSTORE_TYPE       | LDAP_TLS_TRUSTSTORE_TYPE     | (empty)       | Type of the Truststore that is used when connecting to LDAP using LDAPS or START_TLS (i.e. JKS or PKCS12).                                                                                                                                                                                                 |
| TLS - Client Auth               | LDAP_TLS_CLIENT_AUTH           | no such variable             | (empty)       | Client authentication policy when connecting to LDAP using LDAPS or START_TLS. Possible values are REQUIRED, WANT, NONE.                                                                                                                                                                                   |
| TLS - Protocol                  | LDAP_TLS_PROTOCOL              | LDAP_TLS_PROTOCOL            | (empty)       | Protocol to use when connecting to LDAP using LDAPS or START_TLS. (i.e. TLS, TLSv1.1, TLSv1.2, etc).                                                                                                                                                                                                       |
| TLS - Shutdown Gracefully       | LDAP_TLS_SHUTDOWN_GRACEFULLY   | (no variable)                | (empty)       | Specifies whether the TLS should be shut down gracefully before the target context is closed. Defaults to false.                                                                                                                                                                                           |
| Referral Strategy               | LDAP_REFERRAL_STRATEGY         | (no variable)                | FOLLOW        | Strategy for handling referrals. Possible values are FOLLOW, IGNORE, THROW.                                                                                                                                                                                                                                |
| Connect Timeout                 | LDAP_CONNECT_TIMEOUT           | (no variable)                | 10 secs       | Duration of connect timeout. (i.e. 10 secs).                                                                                                                                                                                                                                                               |
| Read Timeout                    | LDAP_READ_TIMEOUT              | (no variable)                | 10 secs       | Duration of read timeout. (i.e. 10 secs).                                                                                                                                                                                                                                                                  |
| Url                             | LDAP_URL                       | LDAP_URL                     | (empty)       | Space-separated list of URLs of the LDAP servers (i.e. ldap://<hostname>:<port>).                                                                                                                                                                                                                          |
| User Search Base                | LDAP_USER_SEARCH_BASE          | LDAP_USER_SEARCH_BASE        | (empty)       | Base DN for searching for users (i.e. CN=Users,DC=example,DC=com).                                                                                                                                                                                                                                         |
| User Search Filter              | LDAP_USER_SEARCH_FILTER        | LDAP_USER_SEARCH_FILTER      | (empty)       | Filter for searching for users against the 'User Search Base'. (i.e. sAMAccountName={0}). The user specified name is inserted into '{0}'.                                                                                                                                                                  |
| Identity Strategy               | LDAP_IDENTITY_STRATEGY         | LDAP_IDENTITY_STRATEGY       | USE_USERNAME  | Strategy to identify users. Possible values are USE_DN and USE_USERNAME. The default functionality if this property is missing is USE_DN in order to retain backward compatibility. USE_DN will use the full DN of the user entry if possible. USE_USERNAME will use the username the user logged in with. |
| Authentication Expiration       | LDAP_AUTHENTICATION_EXPIRATION | (no variable)                | 12 hours      | The duration of how long the user authentication is valid for. If the user never logs out, they will be required to log back in following this duration.                                                                                                                                                   |

### Standalone Instance, Kerberos
This example as compose: [docker-compose.kerberos.yml](docker-compose.kerberos.yml)
```
    docker run --name nifi-registry \
      -v /path/to/tls/certs/localhost:/opt/certs \
      -p 18080:18080 \
      -e 'INITIAL_ADMIN_IDENTITY=cn=nifi-admin@EXAMPLE.ORG' \
      -e 'NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER=kerberos-identity-provider' \
      -e 'NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH=false' \
      -d \
      michalklempa/nifi-registry:latest
```

Security properties are set as described at
[Kerberos](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#kerberos_identity_provider) section of [Apache NiFi Registry System Administrator’s Guide](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html).
You may also want to set some of the [Kerberos Properties](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#kerberos_properties) in `nifi-registry.properties` file.

Specifically two properties are set:

#### nifi-registry.properties

| nifi-registry.properties property          | Environment variable                     | Provided Value             | Description                                                                                                                                                                                                                                                                                                |
|--------------------------------------------|------------------------------------------|----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| nifi.security.user.login.identity.provider | NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER | kerberos-identity-provider | This indicates what type of login identity provider to use. The default value is blank, can be set to the identifier from a provider in the file specified in nifi.login.identity.provider.configuration.file. Setting this property will trigger NiFi to support username/password authentication.        |
| nifi.registry.security.needClientAuth      | NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH    | false                      | This specifies that connecting clients must authenticate with a client cert. Setting this to false will specify that connecting clients may optionally authenticate with a client cert, but may also login with a username and password against a configured identity provider. The default value is true. |

Kerberos environment variables are rendered into `conf/identity-providers.xml` file as follows:

#### identity-providers.xml

| identity-providers.xml property | Environment variable               | Official image variable | Default Value   | Description                                                                                 |
|---------------------------------|------------------------------------|-------------------------|-----------------|---------------------------------------------------------------------------------------------|
| Default Realm                   | KERBEROS_DEFAULT_REALM             | (no variable)           | NIFI.APACHE.ORG | Default realm to provide when user enters incomplete user principal (i.e. NIFI.APACHE.ORG). |
| Authentication Expiration       | KERBEROS_AUTHENTICATION_EXPIRATION | (no variable)           | 12 hours        | The DN of the manager that is used to bind to the LDAP server to search for users.          |
| Enable Debug                    | KERBEROS_ENABLE_DEBUG              | (no variable)           | false           |                                                                                             |

## Database configuration

Although all the properties in `nifi-registry.properties` file are configurable using the basic name conversion schema described in [Environment variables templating into nifi-registry.properties](#environment-variables-templating-into-nifi-registryproperties),
we will provide database configuration properties and corresponding environmental variables listing here.
This example as compose: [docker-compose.mariadb.yml](docker-compose.mariadb.yml).

| nifi-registry.properties property | Environment variable              | Official image variable        | Default Value                                                                                                                                 | Description                                                                                                                                                                                                                                                                                       |
|-----------------------------------|-----------------------------------|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| nifi.registry.db.url              | NIFI_REGISTRY_DB_URL              | ~~NIFI_REGISTRY_DB_URL~~       | jdbc:h2:./database/nifi-registry-primary;AUTOCOMMIT=OFF;DB_CLOSE_ON_EXIT=FALSE;LOCK_MODE=3;LOCK_TIMEOUT=25000;WRITE_DELAY=0;AUTO_SERVER=FALSE | The full JDBC connection string. The default value will specify a new H2 database in the same location as the previous one. For example, jdbc:h2:./database/nifi-registry-primary;.                                                                                                               |
| nifi.registry.db.driver.class     | NIFI_REGISTRY_DB_DRIVER_CLASS     | ~~NIFI_REGISTRY_DB_CLASS~~     | org.h2.Driver                                                                                                                                 | The class name of the JDBC driver. The default value is org.h2.Driver.                                                                                                                                                                                                                            |
| nifi.registry.db.driver.directory | NIFI_REGISTRY_DB_DRIVER_DIRECTORY | ~~NIFI_REGISTRY_DB_DIR~~       | (empty)                                                                                                                                       | An optional directory containing one or more JARs to add to the classpath. If not specified, it is assumed that the driver JAR is already on the classpath by copying it to the lib directory. The H2 driver is bundled with Registry so it is not necessary to do anything for the default case. |
| nifi.registry.db.driver.username  | NIFI_REGISTRY_DB_USERNAME         | ~~NIFI_REGISTRY_DB_USER~~      | nifireg                                                                                                                                       | The username for the database. The default value is nifireg.                                                                                                                                                                                                                                      |
| nifi.registry.db.password         | NIFI_REGISTRY_DB_PASSWORD         | ~~NIFI_REGISTRY_DB_PASS~~      | nifireg                                                                                                                                       | The password for the database. The default value is nifireg.                                                                                                                                                                                                                                      |
| nifi.registry.db.maxConnections   | NIFI_REGISTRY_DB_MAXcONNECTIONS   | ~~NIFI_REGISTRY_DB_MAX_CONNS~~ | 5                                                                                                                                             | The max number of connections for the connection pool. The default value is 5.                                                                                                                                                                                                                    |
| nifi.registry.db.sql.debug        | NIFI_REGISTRY_DB_SQL_DEBUG        | ~~NIFI_REGISTRY_DB_DEBUG_SQL~~ | false                                                                                                                                         | Whether or not enable debug logging for SQL statements. The default value is false.                                                                                                                                                                                                               |

Example docker command:
```
    docker run --name nifi-registry \
      -v ./mariadb-java-client-2.4.1.jar:/opt/nifi-registry/libs/mariadb-java-client-2.4.1.jar \
      -p 18080:18080 \
      -e 'NIFI_REGISTRY_DB_URL=jdbc:mariadb://localhost:3306/db' \
      -e 'NIFI_REGISTRY_DB_DRIVER_CLASS=org.mariadb.jdbc.Driver' \
      -e 'NIFI_REGISTRY_DB_DRIVER_DIRECTORY=/opt/nifi-registry/libs/' \
      -e 'NIFI_REGISTRY_DB_USERNAME=root' \
      -e 'NIFI_REGISTRY_DB_PASSWORD=myPassword' \
      -d \
      michalklempa/nifi-registry:latest
```

There are examples for various databases:
- [docker-compose.postgres.yml](docker-compose.postgres.yml)
- [docker-compose.mariadb.yml](docker-compose.mariadb.yml) - currently not working (see TODO JIRA-ISSUE)
- [docker-compose.mysql.yml](docker-compose.mysql.yml) - currently not working (see TODO JIRA-ISSUE)

## Flow persistence provider configuration
To select FlowPersistenceProvider use environemnt variable:

| Environment variable | Official image variable         | Possible values     | Default Value | Description                                                                                                                                                                                                                                                                          |
|----------------------|---------------------------------|---------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FLOW_PROVIDER        | ~~NIFI_REGISTRY_FLOW_PROVIDER~~ | file, git, database | file          | Environment variable to discriminate which Flow Persistence Provider section to configure in `providers.xml`. Value `file` maps to `FileSystemFlowPersistenceProvider`, value `git` maps to `GitFlowPersistenceProvider`, value `database` maps to `DatabaseFlowPersistenceProvider` |

### FileSystemFlowPersistenceProvider (default)
Configuring NiFi Registry FileSystemFlowPersistenceProvider needs just one variable:

| providers.xml property | Environment variable                      | Official image variable            | Default Value                   | Description                                                                                                                                                                                                                                         |  |
|------------------------|-------------------------------------------|------------------------------------|---------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--|
| Flow Storage Directory | FLOW_PROVIDER_FILE_FLOW_STORAGE_DIRECTORY | ~~NIFI_REGISTRY_FLOW_STORAGE_DIR~~ | /opt/nifi-registry/flow-storage | Default value is set by image, original default value was "./flow-storage". REQUIRED: File system path for a directory where flow contents files are persisted to. If the directory does not exist when NiFi Registry starts, it will be created. If the directory exists, it must be readable and writable from NiFi Registry. |  |

### GitFlowPersistenceProvider
To configure NiFi Registry [GitFlowPersistenceProvider](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#gitflowpersistenceprovider) provide these variables:

| providers.xml property | Environment variable                     | Official image variable            | Default Value                   | Description                                                                                                                                                                                                                                                                                                                                                                                  |
|------------------------|------------------------------------------|------------------------------------|---------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Flow Storage Directory | FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY | ~~NIFI_REGISTRY_FLOW_STORAGE_DIR~~ | /opt/nifi-registry/flow-storage | Default value is set by image, original default value was "./flow-storage". REQUIRED: File system path for a directory where flow contents files are persisted to. The directory must exist when NiFi registry starts. Also must be initialized as a Git directory. See Initialize Git directory for detail.                                                                                 |
| Remote To Push         | FLOW_PROVIDER_GIT_REMOTE_TO_PUSH         | ~~NIFI_REGISTRY_GIT_REMOTE~~       | (empty)                         | When a new flow snapshot is created, this persistence provider updated files in the specified Git directory, then create a commit to the local repository. If Remote To Push is defined, it also pushes to the specified remote repository. E.g. origin. To define more detailed remote spec such as branch names, use Refspec. See https://git-scm.com/book/en/v2/Git-Internals-The-Refspec |
| Remote Access User     | FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER     | ~~NIFI_REGISTRY_GIT_USER~~         | (empty)                         | This user name is used to make push requests to the remote repository when Remote To Push is enabled, and the remote repository is accessed by HTTP protocol. If SSH is used, user authentication is done with SSH keys.                                                                                                                                                                     |
| Remote Access Password | FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD | ~~NIFI_REGISTRY_GIT_PASSWORD~~     | (empty)                         | Used with Remote Access User.                                                                                                                                                                                                                                                                                                                                                                |

### DatabaseFlowPersistenceProvider
NiFi Registry [DatabaseFlowPersistenceProvider](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#databaseflowpersistenceprovider) currently does not need any additional configuration.                                                                                                                                                                                                                                                                                                                     |

## Git cloning the repository at startup
This image is capable of cloning remote git repository at container startup, if the `FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY` does not exist.
Configuring Git cloning and checking out of branch needs a combination of NiFi configuration variables
and some variable we added for the clone scripts.

### Git user.name and user.email
First, we recommend setting these variables to initialize `git config` for git repository.

| Environment variable  | Default Value           | Description                                                                           |
|-----------------------|-------------------------|---------------------------------------------------------------------------------------|
| GIT_CONFIG_USER_NAME  | nifi-registry           | Value of `user.name` property in git configuration. Set locally for this repository.  |
| GIT_CONFIG_USER_EMAIL | nifi-registry@localhost | Value of `user.email` property in git configuration. Set locally for this repository. |

Any variable name prefixed with `GIT_CONFIG` will be converted into git configuration and applied in repository working directory (that is `FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY`),
using the standard way of conversion (see [Environment variables templating into nifi-registry.properties](#environment-variables-templating-into-nifi-registryproperties)).

### Cloning using HTTPS
To clone repository using HTTPS scheme set these properties:

| Environment variable                     | Default Value                   | Description                                                                                                                                                                                                              |
|------------------------------------------|---------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| GIT_REMOTE_URL                           | (empty)                         | URL of the remote git repository, e.g. https://github.com/michalklempa/docker-nifi-registry-example-flow.git                                                                                                             |
| GIT_CHECKOUT_BRANCH                      | (empty)                         | Branch to checkout and track. If none is specified, repository is only cloned and no branch switching is done.                                                                                                           |
| FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY | /opt/nifi-registry/flow-storage | Default value is set by image, original default value was "./flow-storage". This variable is used in clone script as a destination directory for clone. It is also used in NiFi Registry configuration.                  |
| FLOW_PROVIDER_GIT_REMOTE_TO_PUSH         | (empty)                         | This variable is used in clone script to set origin name using `-o, --origin <name>   use <name> instead of 'origin' to track upstream`. It is also used in NiFi Registry configuration.                                 |
| FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER     | (empty)                         | username                                                                                                                                                                                                                 |
| FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD | (empty)                         | password                                                                                                                                                                                                                 |

Please always provide values for all these variables. There are no reasonable defaults baked in the image.
Example docker run command:
```
    docker run --name nifi-registry \
      -p 18080:18080 \
      -e 'FLOW_PROVIDER=git' \
      -e 'GIT_REMOTE_URL=https://github.com/michalklempa/docker-nifi-registry-example-flow.git' \
      -e 'GIT_CHECKOUT_BRANCH=example' \
      -e 'FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY=/opt/nifi-registry/flow-storage-git' \
      -e 'FLOW_PROVIDER_GIT_REMOTE_TO_PUSH=origin' \
      -e 'FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER=michalklempa' \
      -e 'FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD=thisisnotmypassword:)' \
      -e 'GIT_CONFIG_USER_NAME=Michal Klempa' \
      -e 'GIT_CONFIG_USER_EMAIL=michalklempa@gmail.com' \
      -d \
      michalklempa/nifi-registry:latest
```
Image will run at startup. Credential helper hack (https://stackoverflow.com/a/43022442/3944551) is run only if `FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD` is set.
```
    git config --global credential.${GIT_REMOTE_URL}.helper '!f() { sleep 1; echo -e "username=${FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER}\npassword=${FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD}"; }; f'
    git clone -o $FLOW_PROVIDER_GIT_REMOTE_TO_PUSH -b $GIT_CHECKOUT_BRANCH $GIT_REMOTE_URL $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY
    git config -f $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY/.git/config 'user.name' $GIT_CONFIG_USER_NAME
    git config -f $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY/.git/config 'user.email' $GIT_CONFIG_USER_EMAIL
```

### Cloning using GIT+SSH
To clone repository using git+ssh scheme either set these properties, or mount `.ssh` into `/home/nifi/.ssh`:

#### SSH keys using environemnt variables
*Note*: At the time being, the `SSH_PRIVATE_KEY_PASSPHRASE` is used by image when cloning the git
 repository. But NiFi Registry has limitation, that the private key must be password-less (see https://lists.apache.org/thread.html/357fb7938dd18cf17c12a15cf8aac77d95d67ec4c6d8fc6eae998915@%3Cusers.nifi.apache.org%3E).
 Until NiFi Registry supports password-protected private keys, the option `SSH_PRIVATE_KEY_PASSPHRASE` is unusable.

| Environment variable                     | Default Value                   | Description                                                                                                                                                                                                              |
|------------------------------------------|---------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| GIT_REMOTE_URL                           | (empty)                         | URL of the remote git repository, e.g. git@github.com:michalklempa/docker-nifi-registry-example-flow.git                                                                                                                 |
| GIT_CHECKOUT_BRANCH                      | (empty)                         | Branch to checkout and track. If none is specified, repository is only cloned and no branch switching is done.                                                                                                           |
| FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY | /opt/nifi-registry/flow-storage | Default value is set by image, original default value was "./flow-storage". This variable is used in clone script as a destination directory for clone. It is also used in NiFi Registry configuration.                  |
| FLOW_PROVIDER_GIT_REMOTE_TO_PUSH         | (empty)                         | This variable is used in clone script to set origin name using `-o, --origin <name>   use <name> instead of 'origin' to track upstream`. It is also used in NiFi Registry configuration.                                 |
| FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER     | (empty)                         | username                                                                                                                                                                                                                 |
| SSH_PRIVATE_KEY                          | (empty)                         | Private key for system SSH client in exact same form as it used by OpenSSH. This key will get stored into `/home/nifi/.ssh/`                                                                                             |
| SSH_PRIVATE_KEY_PASSPHRASE               | (empty)                         | If the private key is encrypted, provide the passphrase to decrypt it.                                                                                                                                                   |
| SSH_KNOWN_HOSTS                          | (empty)                         | Contents of the `known_hosts` file.                                                                                                                                                                                      |

Please always provide values for all these variables. There are no reasonable defaults baked in the image.
If you want to obtain host key for known_hosts, run this command:
```
ssh-keyscan -H -t rsa github.com > ~/.ssh/known_hosts_nifi_registry
```
As JSch library, used by NiFi Registry checks RSA host keys and fails with ecdsa.

Example docker run command:
```
    docker run --name nifi-registry \
      -p 18080:18080 \
      -e 'FLOW_PROVIDER=git' \
      -e 'GIT_REMOTE_URL=git@github.com:michalklempa/docker-nifi-registry-example-flow.git' \
      -e 'GIT_CHECKOUT_BRANCH=example' \
      -e 'FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY=/opt/nifi-registry/flow-storage-git' \
      -e 'FLOW_PROVIDER_GIT_REMOTE_TO_PUSH=origin' \
      -e 'GIT_CONFIG_USER_NAME=Michal Klempa' \
      -e 'GIT_CONFIG_USER_EMAIL=michal.klempa@gmail.com' \
      -e 'SSH_PRIVATE_KEY='$(base64 -w 0 < ~/.ssh/id_rsa) \
      -e 'SSH_KNOWN_HOSTS='$(base64 -w 0 < ~/.ssh/known_hosts_nifi_registry) \
      -e 'SSH_PRIVATE_KEY_PASSPHRASE=' \
      -d \
      michalklempa/nifi-registry:latest
```
Image will run at startup:
```
    echo -n ${SSH_PRIVATE_KEY} | base64 -d > $SSH_PRIVATE_KEY_FILE && chmod 600 $SSH_PRIVATE_KEY_FILE
    ssh-keygen ${SSH_PRIVATE_KEY_PASSPHRASE:+'-P' "${SSH_PRIVATE_KEY_PASSPHRASE}"} -y -f $SSH_PRIVATE_KEY_FILE > ${SSH_PRIVATE_KEY_FILE}.pub && chmod 600 ${SSH_PRIVATE_KEY_FILE}.pub
    echo -n ${SSH_KNOWN_HOSTS} | base64 -d > $SSH_KNOWN_HOSTS_FILE && chmod 600 $SSH_KNOWN_HOSTS_FILE
    export GIT_SSH_COMMAND="sshpass -e -P'assphrase' ssh"
    export SSHPASS=${SSH_PRIVATE_KEY_PASSPHRASE}
    git clone -o $FLOW_PROVIDER_GIT_REMOTE_TO_PUSH -b $GIT_CHECKOUT_BRANCH $GIT_REMOTE_URL $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY
    git config -f $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY/.git/config 'user.name' $GIT_CONFIG_USER_NAME
    git config -f $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY/.git/config 'user.email' $GIT_CONFIG_USER_EMAIL
```

#### SSH keys using mount point

Another option to provide SSH key is to add a bind mount:

```
    docker run --name nifi-registry \
      -p 18080:18080 \
      -v ~/.ssh:/home/nifi/.ssh \
      -e 'FLOW_PROVIDER=git' \
      -e 'GIT_REMOTE_URL=git@github.com:michalklempa/docker-nifi-registry-example-flow.git' \
      -e 'GIT_CHECKOUT_BRANCH=example' \
      -e 'FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY=/opt/nifi-registry/flow-storage-git' \
      -e 'FLOW_PROVIDER_GIT_REMOTE_TO_PUSH=origin' \
      -e 'GIT_CONFIG_USER_NAME=Michal Klempa' \
      -e 'GIT_CONFIG_USER_EMAIL=michal.klempa@gmail.com' \
      -d \
      michalklempa/nifi-registry:latest
```
You **must avoid** setting `SSH_PRIVATE_KEY`, setting this will trigger former behavior, thus rewriting your keys!

## Bundle Persistence Providers configuration

To select FileSystemBundlePersistenceProvider use environemnt variable:

| Environment variable | Official image variable         | Possible values | Default Value | Description                                                                                                                                                                                                              |
|----------------------|---------------------------------|-----------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| EXTENSION_BUNDLE_PROVIDER        | ~~NIFI_REGISTRY_BUNDLE_PROVIDER~~ | file, s3       | file          | Environment variable to discriminate which Bundle Extension Persistence Provider section to configure in `providers.xml`. Value `file` maps to `FileSystemBundlePersistenceProvider`, value `s3` maps to `S3BundlePersistenceProvider` |

### FileSystemBundlePersistenceProvider (default)
Configuring NiFi Registry FileSystemBundlePersistenceProvider needs just one variable:

| providers.xml property             | Environment variable                                              | Official image variable            | Default Value                               | Description                                                                                                                                                                                                                                                                                                                                      |
|------------------------------------|-------------------------------------------------------------------|------------------------------------|---------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Extension Bundle Storage Directory | EXTENSION_BUNDLE_PROVIDER_FILE_EXTENSION_BUNDLE_STORAGE_DIRECTORY | ~~NIFI_REGISTRY_BUNDLE_STORAGE_DIR~~ | /opt/nifi-registry/extension-bundle-storage | Default value is set by image, original default value was "./extension_bundles". REQUIRED: File system path for a directory where extension bundle contents files are persisted to. If the directory does not exist when NiFi Registry starts, it will be created. If the directory exists, it must be readable and writable from NiFi Registry. |

### S3BundlePersistenceProvider
To configuring NiFi Registry S3BundlePersistenceProvider provide these variables:

| providers.xml property | Environment variable                              | Official image variable                   | Default Value | Description                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|------------------------|---------------------------------------------------|-------------------------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Region                 | EXTENSION_BUNDLE_PROVIDER_S3_REGION               | ~~NIFI_REGISTRY_S3_REGION~~               | (empty)       | REQUIRED: The name of the S3 region where the bucket exists.                                                                                                                                                                                                                                                                                                                                                                                           |
| Bucket Name            | EXTENSION_BUNDLE_PROVIDER_S3_BUCKET_NAME          | ~~NIFI_REGISTRY_S3_BUCKET_NAME~~          | (empty)       | REQUIRED: The name of an existing bucket to store extension bundles.                                                                                                                                                                                                                                                                                                                                                                                   |
| Key Prefix             | EXTENSION_BUNDLE_PROVIDER_S3_KEY_PREFIX           | ~~NIFI_REGISTRY_S3_KEY_PREFIX~~           | (empty)       | An optional prefix that if specified will be added to the beginning of all S3 keys.                                                                                                                                                                                                                                                                                                                                                                    |
| Credentials Provider   | EXTENSION_BUNDLE_PROVIDER_S3_CREDENTIALS_PROVIDER | ~~NIFI_REGISTRY_S3_CREDENTIALS_PROVIDER~~ | DEFAULT_CHAIN | REQUIRED: Indicates how credentials will be provided, must be a value of DEFAULT_CHAIN or STATIC. DEFAULT_CHAIN will consider in order: Java system properties, environment variables, credential profiles (~/.aws/credentials). STATIC requires that Access Key and Secret Access Key be specified directly in this file. For Docker image, using the DEFAULT_CHAIN probably does not make a sense. Use STATIC and provide access key and secret key. |
| Access Key             | EXTENSION_BUNDLE_PROVIDER_S3_ACCESS_KEY           | ~~NIFI_REGISTRY_S3_ACCESS_KEY~~           | (empty)       | The access key to use when using STATIC credentials provider.                                                                                                                                                                                                                                                                                                                                                                                          |
| Secret Access Key      | EXTENSION_BUNDLE_PROVIDER_S3_SECRET_ACCESS_KEY    | ~~NIFI_REGISTRY_S3_SECRET_ACCESS_KEY~~    | (empty)       | The secret access key to use when using STATIC credentials provider.                                                                                                                                                                                                                                                                                                                                                                                   |
| Endpoint URL           | EXTENSION_BUNDLE_PROVIDER_S3_ENDPOINT_URL         | ~~NIFI_REGISTRY_S3_ENDPOINT_URL~~         | (empty)       | An optional URL that overrides the default AWS S3 endpoint URL. Set this when using an AWS S3 API compatible service hosted at a different URL.                                                                                                                                                                                                                                                                                                        |

Please always provide values for all these variables. There are no reasonable defaults baked in the image.
Example docker run command:
```
    docker run --name nifi-registry \
      -p 18080:18080 \
      -e 'EXTENSION_BUNDLE_PROVIDER=s3' \
      -e 'EXTENSION_BUNDLE_PROVIDER_S3_REGION=eu-central-1' \
      -e 'EXTENSION_BUNDLE_PROVIDER_S3_BUCKET_NAME=nifi-registry-extension-bundles' \
      -e 'EXTENSION_BUNDLE_PROVIDER_S3_KEY_PREFIX=/bundles' \
      -e 'EXTENSION_BUNDLE_PROVIDER_S3_CREDENTIALS_PROVIDER=static' \
      -e 'EXTENSION_BUNDLE_PROVIDER_S3_ACCESS_KEY=AKIA239057ASLKJAGLKP' \
      -e 'EXTENSION_BUNDLE_PROVIDER_S3_SECRET_ACCESS_KEY=KLASFnewewSDF932FSAKLJsda+SDFdskjgw+AFSK' \
      -d \
      michalklempa/nifi-registry:latest
```

## Providing configuration by mounting files

In some environments, like `docker-compose`  or Kubernetes, it may be useful to provide
configuration files directly from outside without modifications on them using environment variables.

To provide all needed configuration files as volumes from outside, grab the image label `-plain`. These images do not have any templating in startup script.  
You have to provide all files or the upstream defaults are used. You may also mount the whole `./conf` directory.

Plain images do not setup user `nifi` and group `nifi`. You may want to set it up yourself, see [Running under different UID:GID](#running-under-different-uidgid).

Example:
```
 docker run --name nifi-registry \
      -p 18080:18080 \
      -v $PWD/conf/bootstrap.conf:/opt/nifi-registry/nifi-registry-0.5.0/conf/bootstrap.conf \
      -v $PWD/conf/nifi-registry.properties:/opt/nifi-registry/nifi-registry-0.5.0/conf/nifi-registry.properties \
      -v $PWD/conf/authorizers.xml:/opt/nifi-registry/nifi-registry-0.5.0/conf/authorizers.xml \
      -v $PWD/conf/identity-providers.xml:/opt/nifi-registry/nifi-registry-0.5.0/conf/identity-providers.xml \
      -v $PWD/conf/providers.xml:/opt/nifi-registry/nifi-registry-0.5.0/conf/providers.xml \
      -d \
      michalklempa/nifi-registry:0.5.0-plain
```

## Running under different UID:GID
By default, the images have user `nifi` with group `nifi` embedded under UID:GID of 1000:1000.
This may cause problems when binding or mounting volumes to the container.
Usually, one needs to have exacts same UID:GID on host machine as is used inside container.

### Running as root
You may want to run the image under `root` user, for this purpose, use the images labeled `default`:
```
 docker run --name nifi-registry \
      -p 18080:18080 \
      -v $PWD/conf/bootstrap.conf:/opt/nifi-registry/nifi-registry-0.5.0/conf/bootstrap.conf \
      -v $PWD/conf/nifi-registry.properties:/opt/nifi-registry/nifi-registry-0.5.0/conf/nifi-registry.properties \
      -v $PWD/conf/authorizers.xml:/opt/nifi-registry/nifi-registry-0.5.0/conf/authorizers.xml \
      -v $PWD/conf/identity-providers.xml:/opt/nifi-registry/nifi-registry-0.5.0/conf/identity-providers.xml \
      -v $PWD/conf/providers.xml:/opt/nifi-registry/nifi-registry-0.5.0/conf/providers.xml \
      -d \
      michalklempa/nifi-registry:0.5.0-default
```

### Running as custom UID:GID
To run using custom UID:GID (other than 1000:1000), you will have to build your own
image, derived from this one.
As an example, there is [Docker.user.example](Dockerfile.user.example) file in the repository, with contents:
```
FROM michalklempa/nifi-registry:0.5.0-default
ARG UID=1000
ARG GID=1000

RUN addgroup -g ${GID} nifi \
    && adduser -s /bin/bash -u ${UID} -G nifi -D nifi \
    && chown -R nifi:nifi ${PROJECT_BASE_DIR}
USER nifi
```

This is derived from default image running under `root` privileges and adding the desired nifi user and group. To build such image, use this command:
```
docker build -f Dockerfile.user.example --build-arg UID=2006 --build-arg GID=2006 -t michalklempa/nifi-registry-custom-uid-gid:latest .
```
Change the numbers to whatever you need.

## Building
The Docker image can be built using the following command:
```
export DOCKER_TAG=0.5.0-02.plain
export UPSTREAM_VERSION=0.5.0
export MIRROR=https://archive.apache.org/dist
export DOCKERFILE_PATH=Dockerfile
export DOCKER_REPO=michalklempa/nifi-registry
./hooks/build
```

This will result in an image tagged michalklempa/nifi-registry:latest
```
$ docker image ls
REPOSITORY                   TAG                         IMAGE ID            CREATED             SIZE
michalklempa/nifi-registry   0.5.0-02.plain              945ff5472a69        11 hours ago        233MB
```

**Note**: The default version of NiFi Registry specified by the Dockerfile is typically last released version (current: 0.5.0).
To build an image for a prior released version, one can override the `UPSTREAM_VERSION` build-arg with the following command:
```
export DOCKER_TAG={Desired NiFi Registry Version}-01.plain
export UPSTREAM_VERSION={Desired NiFi Registry Version}
export MIRROR=https://archive.apache.org/dist
export DOCKERFILE_PATH=Dockerfile
export DOCKER_REPO=michalklempa/nifi-registry

./hooks/build
```
There is, however, no guarantee that older versions will work as properties have changed and evolved with subsequent releases.

## Contributing
The `templates` were built:
```
./python/swapcase.py BOOTSTRAP_  < conf/bootstrap.conf > templates/bootstrap.conf.gotemplate
```
with optional prefix as arg to swapcase.py, so `nifi-registry.properties.gotemplate` was built:
```
./python/swapcase.py   < conf/nifi-registry.properties > templates/nifi-registry.properties.gotemplate
```
All other templates were designed by hand.

Table of contents is generated using:
```
doctoc README.md
```

## Building Release Candindates
To build a release candidate, we first build from source distribution. This way we obtain:
```
./nifi-assembly/target/nifi-registry-0.6.0-bin.tar.gz
```
Lets setup directory structure as it is at Apache mirror sites:
```
mkdir -p ./nifi/nifi-registry/nifi-registry-0.6.0
```
And move the tar.gz there:
```
mv ./nifi-assembly/target/nifi-registry-0.6.0-bin.tar.gz ./nifi/nifi-registry/nifi-registry-0.6.0/
```
Lets create the sha256 file needed:
```
sha256sum ./nifi/nifi-registry/nifi-registry-0.6.0/nifi-registry-0.6.0-bin.tar.gz > ./nifi/nifi-registry/nifi-registry-0.6.0/nifi-registry-0.6.0-bin.tar.gz.sha256
```

To provide this fake mirror into build process locally, we spin up `nginx` docker image:
```
docker run -v $PWD:/usr/share/nginx/html -p 8080:80 nginx
```

When building the Release Candidate docker image, we spoof the mirror (exact IP address depends on your `docker0` network device) and adjust docker tag:
```
export DOCKER_TAG=0.6.0_RC1-01.plain
export UPSTREAM_VERSION=0.6.0
export MIRROR=http://172.17.0.1:8080/
export DOCKERFILE_PATH=Dockerfile
export DOCKER_REPO=michalklempa/nifi-registry

./hooks/build
```

## Building 1.0.0-SNAPSHOT
Built from [32100bd5e5a49787acb1694cd9751dd1169e6fe7](https://github.com/apache/nifi-registry/commit/32100bd5e5a49787acb1694cd9751dd1169e6fe7):
```
docker build \
  --build-arg VERSION=1.0.0-SNAPSHOT \
  --build-arg COMMIT=$(git rev-parse HEAD) \
  --build-arg URL=$(git config --get remote.origin.url) \
  --build-arg BRANCH=$(git rev-parse --abbrev-ref HEAD) \
  --build-arg DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  -f Dockerfile.master \
  -t michalklempa/nifi-registry:1.0.0-SNAPSHOT .
````
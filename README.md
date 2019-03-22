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

## Notice
This image is inspired by the official image: [apache/nifi-registry](https://hub.docker.com/r/apache/nifi-registry).
The configuration capabilities and options are taken from that image (see the copyright [NOTICE](NOTICE) and [LICENSE](LICENSE)).

The way the image is configured at runtime is reworked to use [Go templates](https://golang.org/pkg/text/template/) 
and the runtime fork & logs capture is handled by [dockerize](https://github.com/jwilder/dockerize).

Image is based on [openjdk:8-jdk-alpine](https://hub.docker.com/_/openjdk).
It is also smaller than the official one (233MB vs. 387MB).

The configuration environment variables are different, so this image is not a drop-in replacement for the official one.
Read the documentation below. We have included the original names in this readme for the convenience, but these are **NOT** supported by this image.
Update your launch scripts accordingly. 

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

| nifi-registry.properties property | Environment variable |
|-----------------------------------|----------------------|
| NIFI_REGISTRY_SECURITY_TRUSTSTOREpASSWD | nifi.registry.security.truststorePasswd |
| NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH   | nifi.registry.security.needClientAuth |


This way, you can set and change any property in `nifi-registry.properties`.
Do not name your own environment variables with prefix `NIFI_REGISTRY`, they will get templated into the properties file.

Image provides additional environmental variables to configure `authorizers.xml`, `identity-providers.xml` and `providers.xml`.
These are described below.

## Running a container
### Standalone Instance, Unsecured
The minimum to run a NiFi Registry instance is as follows:
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

#### NiFi Registry Listen Properties

| nifi-registry.properties property | Environment variable    | Official image variable     | Default Value | Description | 
|-----------------------------------|-------------------------|-----------------------------|---------------|-------------|
| nifi.registry.web.http.host  | NIFI_REGISTRY_WEB_HTTP_HOST  | NIFI_REGISTRY_WEB_HTTP_HOST |(empty)  | Host to bind, can be IP address or hostname. Default empty value causes listening on all interfaces |
| nifi.registry.web.http.port  | NIFI_REGISTRY_WEB_HTTP_PORT  | NIFI_REGISTRY_WEB_HTTP_PORT |  18080    | TCP Port to listen |
| nifi.registry.web.https.host | NIFI_REGISTRY_WEB_HTTPS_HOST | NIFI_REGISTRY_WEB_HTTPS_HOST | (empty)  | Host to bind for HTTPS connections, can be IP address or hostname. Default empty value causes listening on all interfaces |
| nifi.registry.web.https.port | NIFI_REGISTRY_WEB_HTTPS_PORT | NIFI_REGISTRY_WEB_HTTPS_PORT |(empty)  | TCP Port to listen. Default empty, but value `18443` seems to be NiFi Registry standard | 

You may want to consult [Web Properties](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#web-properties) section of [Apache NiFi Registry System Administrator’s Guide](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html)

### Standalone Instance, Two-Way SSL
In this configuration, the user will need to provide certificates and the associated configuration information.
The user must provide the DN as provided by an accessing client certificate in the `INITIAL_ADMIN_IDENTITY` environment variable.
This value will be used to seed the instance with an initial user with administrative privileges.
Finally, this command makes use of a volume to provide certificates on the host system to the container instance.
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
| nifi-registry.properties property | Environment variable    | Official image variable     | Default Value | Description | 
|-----------------------------------|-------------------------|-----------------------------|---------------|-------------|
| nifi.registry.security.keystore             | NIFI_REGISTRY_SECURITY_KEYSTORE  | ~~KEYSTORE_PATH~~     | (empty) | Filename of the Keystore that contains the server’s private key. |
| nifi.registry.security.keystoreType         | NIFI_REGISTRY_SECURITY_KEYSTOREtYPE  | ~~KEYSTORE_TYPE~~     | (empty) | The type of Keystore. Must be either PKCS12 or JKS. JKS is the preferred type, PKCS12 files will be loaded with BouncyCastle provider. |
| nifi.registry.security.keystorePasswd       | NIFI_REGISTRY_SECURITY_KEYSTOREpASSWD  | ~~KEYSTORE_PASSWORD~~     | (empty) | The password for the Keystore. |
| nifi.registry.security.truststore           | NIFI_REGISTRY_SECURITY_TRUSTSTORE  | ~~TRUSTSTORE_PATH~~     | (empty) | Filename of the Truststore that will be used to authorize those connecting to NiFi Registry. A secured instance with no Truststore will refuse all incoming connections. |
| nifi.registry.security.truststoreType       | NIFI_REGISTRY_SECURITY_TRUSTSTOREtYPE  | ~~TRUSTSTORE_PASSWORD~~     | (empty) | The type of the Truststore. Must be either PKCS12 or JKS. JKS is the preferred type, PKCS12 files will be loaded with BouncyCastle provider. |
| nifi.registry.security.truststorePasswd     | NIFI_REGISTRY_SECURITY_TRUSTSTOREpASSWD  | ~~TRUSTSTORE_TYPE~~     | (empty) | The password for the Truststore. |
| nifi.registry.security.needClientAuth       | NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH    | no such variable | empty in configuration file, NiFi documentation states default is true. | This specifies that connecting clients must authenticate with a client cert. Setting this to false will specify that connecting clients may optionally authenticate with a client cert, but may also login with a username and password against a configured identity provider. The default value is true. | 

#### authorizers.xml
| authorizers.xml property | Environment variable | Official image variable | Default Value | Description | 
|--------------------------|----------------------|-------------------------|---------------|-------------|
| authorizers/userGroupProvider/property\[name='Initial User Identity 1'\]     | INITIAL_ADMIN_IDENTITY  | INITIAL_ADMIN_IDENTITY     | (empty) | The identity of a user or system to seed an empty Users File. Multiple Initial User Identity properties can be specified, but the name of each property must be unique, for example: "Initial User Identity A", "Initial User Identity B", "Initial User Identity C" or "Initial User Identity 1", "Initial User Identity 2", "Initial User Identity 3". |
| authorizers/accessPolicyProvider/property\[name='Initial Admin Identity'\]   | INITIAL_ADMIN_IDENTITY  | INITIAL_ADMIN_IDENTITY     | (empty) | The identity of an initial admin user that will be granted access to the UI and given the ability to create additional users, groups, and policies. For example, a certificate DN, LDAP identity, or Kerberos principal. |

### Standalone Instance, LDAP
In this configuration, the user will need to provide certificates and the associated configuration information.  Optionally,
if the LDAP provider of interest is operating in LDAPS or START_TLS modes, certificates will additionally be needed.
The user must provide a DN as provided by the configured LDAP server in the `INITIAL_ADMIN_IDENTITY` environment variable.
This value will be used to seed the instance with an initial user with administrative privileges.
Finally, this command makes use of a volume to provide certificates on the host system to the container instance.

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
| nifi-registry.properties property | Environment variable | Provided Value | Description | 
|------------------------------|------------------------------|----------|---------------|
| nifi.security.user.login.identity.provider  | NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER  | ldap-identity-provider | This indicates what type of login identity provider to use. The default value is blank, can be set to the identifier from a provider in the file specified in nifi.login.identity.provider.configuration.file. Setting this property will trigger NiFi to support username/password authentication. |
| nifi.registry.security.needClientAuth | NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH | false | This specifies that connecting clients must authenticate with a client cert. Setting this to false will specify that connecting clients may optionally authenticate with a client cert, but may also login with a username and password against a configured identity provider. The default value is true. |

LDAP environment variables are rendered into `conf/identity-providers.xml` file as follows:

#### identity-providers.xml
| identity-providers.xml property | Environment variable | Official image variable | Default Value | Description | 
|---------------------------------|----------------------|-------------------------|---------------|-------------|
| Authentication Strategy       | LDAP_AUTHENTICATION_STRATEGY | LDAP_AUTHENTICATION_STRATEGY  | SIMPLE | How the connection to the LDAP server is authenticated. Possible values are ANONYMOUS, SIMPLE, LDAPS, or START_TLS. |
| Manager DN  | LDAP_MANAGER_DN | LDAP_MANAGER_DN | (empty)  | The DN of the manager that is used to bind to the LDAP server to search for users. |
| Manager Password              | LDAP_MANAGER_PASSWORD | LDAP_MANAGER_PASSWORD | (empty)  | The password of the manager that is used to bind to the LDAP server to search for users. |
| TLS - Keystore                | LDAP_TLS_KEYSTORE | LDAP_TLS_KEYSTORE | (empty)  | Path to the Keystore that is used when connecting to LDAP using LDAPS or START_TLS. | 
| TLS - Keystore Password       | LDAP_TLS_KEYSTORE_PASSWORD | LDAP_TLS_KEYSTORE_PASSWORD | (empty)  | Password for the Keystore that is used when connecting to LDAP using LDAPS or START_TLS. | 
| TLS - Keystore Type           | LDAP_TLS_KEYSTORE_TYPE | LDAP_TLS_KEYSTORE_TYPE | (empty)  | Type of the Keystore that is used when connecting to LDAP using LDAPS or START_TLS (i.e. JKS or PKCS12). | 
| TLS - Truststore              | LDAP_TLS_TRUSTSTORE | LDAP_TLS_TRUSTSTORE | (empty)  | Path to the Truststore that is used when connecting to LDAP using LDAPS or START_TLS. | 
| TLS - Truststore Password     | LDAP_TLS_TRUSTSTORE_PASSWORD | LDAP_TLS_TRUSTSTORE_PASSWORD | (empty)  | Password for the Truststore that is used when connecting to LDAP using LDAPS or START_TLS. | 
| TLS - Truststore Type         | LDAP_TLS_TRUSTSTORE_TYPE | LDAP_TLS_TRUSTSTORE_TYPE |(empty)  | Type of the Truststore that is used when connecting to LDAP using LDAPS or START_TLS (i.e. JKS or PKCS12). | 
| TLS - Client Auth             | LDAP_TLS_CLIENT_AUTH | no such variable | (empty)  | Client authentication policy when connecting to LDAP using LDAPS or START_TLS. Possible values are REQUIRED, WANT, NONE. | 
| TLS - Protocol                | LDAP_TLS_PROTOCOL | LDAP_TLS_PROTOCOL | (empty)  | Protocol to use when connecting to LDAP using LDAPS or START_TLS. (i.e. TLS, TLSv1.1, TLSv1.2, etc). | 
| TLS - Shutdown Gracefully     | LDAP_TLS_SHUTDOWN_GRACEFULLY | (no variable) | (empty)  | Specifies whether the TLS should be shut down gracefully before the target context is closed. Defaults to false. | 
| Referral Strategy             | LDAP_REFERRAL_STRATEGY | (no variable) | FOLLOW | Strategy for handling referrals. Possible values are FOLLOW, IGNORE, THROW. | 
| Connect Timeout               | LDAP_CONNECT_TIMEOUT | (no variable) | 10 secs  | Duration of connect timeout. (i.e. 10 secs). | 
| Read Timeout                  | LDAP_READ_TIMEOUT | (no variable) | 10 secs  | Duration of read timeout. (i.e. 10 secs). | 
| Url                           | LDAP_URL | LDAP_URL | (empty)  | Space-separated list of URLs of the LDAP servers (i.e. ldap://<hostname>:<port>). | 
| User Search Base              | LDAP_USER_SEARCH_BASE | LDAP_USER_SEARCH_BASE | (empty)  | Base DN for searching for users (i.e. CN=Users,DC=example,DC=com). | 
| User Search Filter            | LDAP_USER_SEARCH_FILTER | LDAP_USER_SEARCH_FILTER | (empty)  | Filter for searching for users against the 'User Search Base'. (i.e. sAMAccountName={0}). The user specified name is inserted into '{0}'. | 
| Identity Strategy             | LDAP_IDENTITY_STRATEGY | LDAP_IDENTITY_STRATEGY | USE_USERNAME  | Strategy to identify users. Possible values are USE_DN and USE_USERNAME. The default functionality if this property is missing is USE_DN in order to retain backward compatibility. USE_DN will use the full DN of the user entry if possible. USE_USERNAME will use the username the user logged in with. | 
| Authentication Expiration     | LDAP_AUTHENTICATION_EXPIRATION | (no variable) | 12 hours | The duration of how long the user authentication is valid for. If the user never logs out, they will be required to log back in following this duration. | 

### Standalone Instance, Kerberos
```
    docker run --name nifi-registry \
      -v /path/to/tls/certs/localhost:/opt/certs \
      -p 18443:18443 \
      -e 'INITIAL_ADMIN_IDENTITY=cn=nifi-admin@EXAMPLE.ORG' \
      -e 'NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER=kerberos-identity-provider'
      -e 'NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH=false'
      -d \
      michalklempa/nifi-registry:latest
```

Security properties are set as described at 
[Kerberos](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#kerberos_identity_provider) section of [Apache NiFi Registry System Administrator’s Guide](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html).
You may also want to set some of the [Kerberos Properties](https://nifi.apache.org/docs/nifi-registry-docs/html/administration-guide.html#kerberos_properties) in `nifi-registry.properties` file. 

Specifically two properties are set:
#### nifi-registry.properties
| nifi-registry.properties property | Environment variable | Provided Value | Description | 
|------------------------------|------------------------------|----------|---------------|
| nifi.security.user.login.identity.provider  | NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER  | kerberos-identity-provider | This indicates what type of login identity provider to use. The default value is blank, can be set to the identifier from a provider in the file specified in nifi.login.identity.provider.configuration.file. Setting this property will trigger NiFi to support username/password authentication. |
| nifi.registry.security.needClientAuth | NIFI_REGISTRY_SECURITY_NEEDcLIENTaUTH | false | This specifies that connecting clients must authenticate with a client cert. Setting this to false will specify that connecting clients may optionally authenticate with a client cert, but may also login with a username and password against a configured identity provider. The default value is true. |

Kerberos environment variables are rendered into `conf/identity-providers.xml` file as follows:
#### identity-providers.xml 
| identity-providers.xml property | Environment variable | Official image variable | Default Value | Description | 
|---------------------------------|----------------------|-------------------------|---------------|-------------|
| Default Realm  | KERBEROS_DEFAULT_REALM | (no variable) | NIFI.APACHE.ORG |Default realm to provide when user enters incomplete user principal (i.e. NIFI.APACHE.ORG). |
| Authentication Expiration | KERBEROS_AUTHENTICATION_EXPIRATION | (no variable)  | 12 hours  | The DN of the manager that is used to bind to the LDAP server to search for users. |
| Enable Debug | KERBEROS_ENABLE_DEBUG | (no variable) | false  |  |

## Database configuration
Although all the properties in `nifi-registry.properties` file are configurable using the basic name conversion schema described in [Environment variables templating into nifi-registry.properties](#Environment-variables-templating-into-nifi-registry.properties),
we will provide database configuration properties and corresponding environmental variables listing here.

| nifi-registry.properties property | Environment variable | Official image variable | Default Value | Description | 
|---------------------------------|----------------------|-------------------------|---------------|-------------|
| nifi.registry.db.url              | NIFI_REGISTRY_DB_URL  | ~~NIFI_REGISTRY_DB_URL~~     | jdbc:h2:./database/nifi-registry-primary;AUTOCOMMIT=OFF;DB_CLOSE_ON_EXIT=FALSE;LOCK_MODE=3;LOCK_TIMEOUT=25000;WRITE_DELAY=0;AUTO_SERVER=FALSE | The full JDBC connection string. The default value will specify a new H2 database in the same location as the previous one. For example, jdbc:h2:./database/nifi-registry-primary;. |
| nifi.registry.db.driver.class     | NIFI_REGISTRY_DB_DRIVER_CLASS  | ~~NIFI_REGISTRY_DB_CLASS~~ | org.h2.Driver | The class name of the JDBC driver. The default value is org.h2.Driver. | 
| nifi.registry.db.driver.directory | NIFI_REGISTRY_DB_DRIVER_DIRECTORY | ~~NIFI_REGISTRY_DB_DIR~~ | (empty) | An optional directory containing one or more JARs to add to the classpath. If not specified, it is assumed that the driver JAR is already on the classpath by copying it to the lib directory. The H2 driver is bundled with Registry so it is not necessary to do anything for the default case. |
| nifi.registry.db.driver.username  | NIFI_REGISTRY_DB_USERNAME  | ~~NIFI_REGISTRY_DB_USER~~  | nifireg | The username for the database. The default value is nifireg. |
| nifi.registry.db.password | NIFI_REGISTRY_DB_PASSWORD  | ~~NIFI_REGISTRY_DB_PASS~~   | nifireg | The password for the database. The default value is nifireg.  |
| nifi.registry.db.maxConnections | NIFI_REGISTRY_DB_MAXcONNECTIONS  | ~~NIFI_REGISTRY_DB_MAX_CONNS~~ | 5 | The max number of connections for the connection pool. The default value is 5.  |
| nifi.registry.db.sql.debug | NIFI_REGISTRY_DB_SQL_DEBUG | ~~NIFI_REGISTRY_DB_DEBUG_SQL~~  |  false | Whether or not enable debug logging for SQL statements. The default value is false.  |

## Flow persistence provider configuration
To select FileSystemFlowPersistenceProvider use environemnt variable:

| Environment variable | Official image variable | Possible values | Default Value | Description | 
|---------------------------------|----------------------|-------------------------|---------------|-------------|
| FLOW_PROVIDER  | ~~NIFI_REGISTRY_FLOW_PROVIDER~~ | file, git  | file | Environment variable to discriminate which Flow Persistence Provider section to configure in `providers.xml`. Value `file` maps to `FileSystemFlowPersistenceProvider`, value `git` maps to `GitFlowPersistenceProvider` |

### FileSystemFlowPersistenceProvider (default)
| providers.xml property | Environment variable | Official image variable | Default Value | Description | 
|---------------------------------|----------------------|-------------------------|---------------|-------------|
| Flow Storage Directory             | FLOW_PROVIDER_FILE_FLOW_STORAGE_DIRECTORY  | ~~NIFI_REGISTRY_FLOW_STORAGE_DIR~~     | REQUIRED: File system path for a directory where flow contents files are persisted to. If the directory does not exist when NiFi Registry starts, it will be created. If the directory exists, it must be readable and writable from NiFi Registry. |

### GitFlowPersistenceProvider
| providers.xml property | Environment variable | Official image variable | Default Value | Description | 
|---------------------------------|----------------------|-------------------------|---------------|-------------|
| Flow Storage Directory | FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY | ~~NIFI_REGISTRY_FLOW_STORAGE_DIR~~     | REQUIRED: File system path for a directory where flow contents files are persisted to. The directory must exist when NiFi registry starts. Also must be initialized as a Git directory. See Initialize Git directory for detail. |
| Remote To Push         | FLOW_PROVIDER_GIT_REMOTE_TO_PUSH         | ~~NIFI_REGISTRY_GIT_REMOTE~~     | When a new flow snapshot is created, this persistence provider updated files in the specified Git directory, then create a commit to the local repository. If Remote To Push is defined, it also pushes to the specified remote repository. E.g. origin. To define more detailed remote spec such as branch names, use Refspec. See https://git-scm.com/book/en/v2/Git-Internals-The-Refspec |
| Remote Access User     | FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER     | ~~NIFI_REGISTRY_GIT_USER~~     | This user name is used to make push requests to the remote repository when Remote To Push is enabled, and the remote repository is accessed by HTTP protocol. If SSH is used, user authentication is done with SSH keys. |
| Remote Access Password | FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD | ~~NIFI_REGISTRY_GIT_PASSWORD~~     | Used with Remote Access User. |


## Building
The Docker image can be built using the following command:
```
$ docker build \
    --build-arg VERSION=$(git describe --tags --always) \
    --build-arg COMMIT=$(git rev-parse HEAD) \
    --build-arg URL=$(git config --get remote.origin.url) \
    --build-arg BRANCH=$(git rev-parse --abbrev-ref HEAD) \
    --build-arg DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    -f Dockerfile \
    -t michalklempa/nifi-registry:latest .
```

This will result in an image tagged michalklempa/nifi-registry:latest

    $ docker images
    > REPOSITORY               TAG           IMAGE ID            CREATED                  SIZE
    > michalklempa/nifi-registry     latest        751428cbf631        Now    342MB
    
**Note**: The default version of NiFi Registry specified by the Dockerfile is typically last released version (current: 0.3.0).
To build an image for a prior released version, one can override the `UPSTREAM_VERSION` build-arg with the following command:
```
$ docker build \
    --build-arg VERSION=$(git describe --tags --always) \
    --build-arg COMMIT=$(git rev-parse HEAD) \
    --build-arg URL=$(git config --get remote.origin.url) \
    --build-arg BRANCH=$(git rev-parse --abbrev-ref HEAD) \
    --build-arg DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg UPSTREAM_VERSION={Desired NiFi Registry Version} \
    -f Dockerfile \
    -t michalklempa/nifi-registry:latest .
```
There is, however, no guarantee that older versions will work as properties have changed and evolved with subsequent releases.

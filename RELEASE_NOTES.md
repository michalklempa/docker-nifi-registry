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

## Release notes

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Notice](#notice)
- [Capabilities](#capabilities)
- [Environment variables templating into nifi-registry.properties](#environment-variables-templating-into-nifi-registryproperties)
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
- [Git cloning the repository at startup](#git-cloning-the-repository-at-startup)
  - [Git user.name and user.email](#git-username-and-useremail)
  - [Cloning using HTTPS](#cloning-using-https)
  - [Cloning using GIT+SSH](#cloning-using-gitssh)
    - [SSH keys using environemnt variables](#ssh-keys-using-environemnt-variables)
    - [SSH keys using mount point](#ssh-keys-using-mount-point)
- [Providing configuration by mounting files](#providing-configuration-by-mounting-files)
- [Building](#building)
- [Contributing](#contributing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

 
## NiFi Registry 0.4.0-SNAPSHOT 
 - Added templating for [Bundle Persistence Providers](README.md#bundle-persistence-providers-configuration)
 - 
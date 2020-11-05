# Unofficial Docker Image For NiFi Registry

## Release notes

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [NiFi Registry 0.4.0](#nifi-registry-040)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## NiFi Registry 0.4.0 
 - Added templating for [Bundle Persistence Providers](README.md#bundle-persistence-providers-configuration) 

## NiFi Registry 0.5.0 
 - Added templating for [org.apache.nifi.registry.provider.flow.DatabaseFlowPersistenceProvider](README.md#) 

## NiFi Registry 0.5.0 (0.5.0-03.plain and 0.5.0-03)
 - Added -plain flavored images, these do not set UIG:GID (nifi:nifi) and do not render any config templates. Suitable for k8s deployments.

## NiFi Registry 0.6.0
 - Added -plain, -default flavored images
    - 0.6.0-plain: no UID:GID set (running as root), env var templating TURNED OFF.
    - 0.6.0-default: no UID:GID set (running as root), ENV var templating is done
    - 0.6.0: UID:GID set to nifi:nifi (1000:1000), ENV var templating is done 

## NiFi Registry 0.7.0
 - upstream added possibility to clone repo (default branch), which we kindly ignore

## NiFi Registry 0.8.0
 - new `nifi-registry.properties`:
  ```
# OIDC #
nifi.registry.security.user.oidc.discovery.url=
nifi.registry.security.user.oidc.connect.timeout=
nifi.registry.security.user.oidc.read.timeout=
nifi.registry.security.user.oidc.client.id=
nifi.registry.security.user.oidc.client.secret=
nifi.registry.security.user.oidc.preferred.jwsalgorithm=
  ```
 - new `DatabaseUserGroupProvider` in `authorizers.xml`, since we do not template this file, we ignore
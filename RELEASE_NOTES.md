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

- [NiFi Registry 0.4.0](#nifi-registry-040)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## NiFi Registry 0.4.0 
 - Added templating for [Bundle Persistence Providers](README.md#bundle-persistence-providers-configuration) 

## NiFi Registry 0.5.0 
 - Added templating for [org.apache.nifi.registry.provider.flow.DatabaseFlowPersistenceProvider](README.md#) 

## NiFi Registry 0.5.0 (0.5.0-03.plain and 0.5.0-03)
 - Added -plain flavored images, these do not set UIG:GID (nifi:nifi) and do not render any config templates. Suitable for k8s deployments.

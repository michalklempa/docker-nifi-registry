#!/bin/sh -e

#    Licensed to the Apache Software Foundation (ASF) under one or more
#    contributor license agreements.  See the NOTICE file distributed with
#    this work for additional information regarding copyright ownership.
#    The ASF licenses this file to You under the Apache License, Version 2.0
#    (the "License"); you may not use this file except in compliance with
#    the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

/usr/local/bin/dockerize \
  -template ${PROJECT_TEMPLATE_DIR}/nifi-registry.properties.gotemplate:${PROJECT_CONF_DIR}/nifi-registry.properties \
  -template ${PROJECT_TEMPLATE_DIR}/authorizers.xml.gotemplate:${PROJECT_CONF_DIR}/authorizers.xml \
  -template ${PROJECT_TEMPLATE_DIR}/identity-providers.xml.gotemplate:${PROJECT_CONF_DIR}/identity-providers.xml \
  -template ${PROJECT_TEMPLATE_DIR}/providers.xml.gotemplate:${PROJECT_CONF_DIR}/providers.xml

# Continuously provide logs so that 'docker logs' can produce them
tail -F "${PROJECT_HOME}/logs/nifi-registry-app.log" &
"${PROJECT_HOME}/bin/nifi-registry.sh" run &
nifi_registry_pid="$!"

trap "echo Received trapped signal, beginning shutdown...;" KILL TERM HUP INT EXIT;

echo NiFi-Registry running with PID ${nifi_registry_pid}.
wait ${nifi_registry_pid}
#!/bin/bash -e

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
#    WITH OUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

if [[ -n "$DEBUG" ]]; then
    echo 'Printing all environment variables for debugging'
    env | sort
    echo 'End of debug output'
fi

if [[ -n "$SSH_PRIVATE_KEY" ]]; then
    printf "%s\n" 'SSH_PRIVATE_KEY_FILE=$HOME/.ssh/id_rsa'
    SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_rsa"

    printf "%s\n" 'SSH_KNOWN_HOSTS_FILE=$HOME/.ssh/known_hosts'
    SSH_KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

    printf "%s\n" 'mkdir -p $HOME/.ssh && chmod 700 $HOME/.ssh'
    mkdir -p $HOME/.ssh && chmod 700 $HOME/.ssh

    printf "%s\n" 'echo -n "${SSH_PRIVATE_KEY}" | base64 -d > $SSH_PRIVATE_KEY_FILE && chmod 600 "${SSH_PRIVATE_KEY_FILE}"'
    echo -n "${SSH_PRIVATE_KEY}" | base64 -d > ${SSH_PRIVATE_KEY_FILE} && chmod 600 "${SSH_PRIVATE_KEY_FILE}"

    printf "%s\n" 'ssh-keygen ${SSH_PRIVATE_KEY_PASSPHRASE:+'\''-P'\'' "${SSH_PRIVATE_KEY_PASSPHRASE}"} -y -f ${SSH_PRIVATE_KEY_FILE} > ${SSH_PRIVATE_KEY_FILE}.pub && chmod 600 ${SSH_PRIVATE_KEY_FILE}.pub'
    ssh-keygen ${SSH_PRIVATE_KEY_PASSPHRASE:+'-P' "${SSH_PRIVATE_KEY_PASSPHRASE}"} -y -f ${SSH_PRIVATE_KEY_FILE} > ${SSH_PRIVATE_KEY_FILE}.pub && chmod 600 ${SSH_PRIVATE_KEY_FILE}.pub

    printf "%s\n" 'echo -n ${SSH_KNOWN_HOSTS} | base64 -d > $SSH_KNOWN_HOSTS_FILE && chmod 600 $SSH_KNOWN_HOSTS_FILE'
    echo -n ${SSH_KNOWN_HOSTS} | base64 -d > $SSH_KNOWN_HOSTS_FILE && chmod 600 $SSH_KNOWN_HOSTS_FILE
fi

if [[ -n "$GIT_REMOTE_URL" && ! -d "$FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY" ]]; then
    if [[ -n "$FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD" ]]; then
        echo "FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD is set, trying to set git credential helper for HTTPS password"
        printf "%s\n" 'git config --global credential.${GIT_REMOTE_URL}.helper '\''!f() { sleep 1; echo -e "username=${FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER}\npassword=*****"; }; f'\'
        git config --global credential.${GIT_REMOTE_URL}.helper '!f() { sleep 1; echo -e "username=${FLOW_PROVIDER_GIT_REMOTE_ACCESS_USER}\npassword=${FLOW_PROVIDER_GIT_REMOTE_ACCESS_PASSWORD}"; }; f'
    fi
    if [[ -n "$SSH_PRIVATE_KEY_PASSPHRASE" ]]; then
        printf 'SSH_PRIVATE_KEY_PASSPHRASE is set, hacking git ssh command with sshpass\n'
        printf "%s\n" 'export GIT_SSH_COMMAND="sshpass -e -P'assphrase' ssh"'
        export GIT_SSH_COMMAND="sshpass -e -P'assphrase' ssh"
        printf "%s\n" 'export SSHPASS=${SSH_PRIVATE_KEY_PASSPHRASE}'
        export SSHPASS=${SSH_PRIVATE_KEY_PASSPHRASE}
    fi
    printf "Found git remote: %s, cloning into: %s, with remote: %s and branch: %s\n" ${GIT_REMOTE_URL} ${FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY} ${FLOW_PROVIDER_GIT_REMOTE_TO_PUSH} ${GIT_CHECKOUT_BRANCH}
    printf "%s\n" 'git clone -o $FLOW_PROVIDER_GIT_REMOTE_TO_PUSH -b $GIT_CHECKOUT_BRANCH $GIT_REMOTE_URL $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY'
    git clone -o $FLOW_PROVIDER_GIT_REMOTE_TO_PUSH -b $GIT_CHECKOUT_BRANCH $GIT_REMOTE_URL $FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY
    for KEY in $(compgen -e); do
        if [[ $KEY == GIT_CONFIG* ]]; then
            printf "Found key: %s for git config\n" $KEY
            VALUE=${!KEY}
            KEY=${KEY#GIT_CONFIG_}
            KEY=${KEY~~}
            KEY=${KEY//_/.}
            printf "Setting git config: %s=%s\n" "${KEY}" "${VALUE}"
            printf "%s\n" 'git config -f ${FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY}/.git/config ${KEY} '\''${VALUE}'\'
            git config -f "${FLOW_PROVIDER_GIT_FLOW_STORAGE_DIRECTORY}/.git/config" "${KEY}" "'${VALUE}'"
        fi
    done
fi

if [[ -n "${!BOOTSTRAP_*}" ]]; then
    /usr/local/bin/dockerize -template ${PROJECT_TEMPLATE_DIR}/bootstrap.conf.gotemplate:${PROJECT_CONF_DIR}/bootstrap.conf
fi
if [[ -n "${!NIFI_REGISTRY*}" ]]; then
    /usr/local/bin/dockerize -template ${PROJECT_TEMPLATE_DIR}/nifi-registry.properties.gotemplate:${PROJECT_CONF_DIR}/nifi-registry.properties
fi
if [[ -n "${INITIAL_ADMIN_IDENTITY}" ]]; then
    /usr/local/bin/dockerize -template ${PROJECT_TEMPLATE_DIR}/authorizers.xml.gotemplate:${PROJECT_CONF_DIR}/authorizers.xml
fi
if [[ -n "${NIFI_REGISTRY_SECURITY_IDENTITY_PROVIDER}" ]]; then
    /usr/local/bin/dockerize -template ${PROJECT_TEMPLATE_DIR}/identity-providers.xml.gotemplate:${PROJECT_CONF_DIR}/identity-providers.xml
fi
if [[ -n "${FLOW_PROVIDER}" ]]; then
    /usr/local/bin/dockerize -template ${PROJECT_TEMPLATE_DIR}/providers.xml.gotemplate:${PROJECT_CONF_DIR}/providers.xml
fi

# Continuously provide logs so that 'docker logs' can produce them
tail -F "${PROJECT_HOME}/logs/nifi-registry-app.log" &
"${PROJECT_HOME}/bin/nifi-registry.sh" run &
nifi_registry_pid="$!"

trap "echo Received trapped signal, beginning shutdown...;" KILL TERM HUP INT EXIT;

echo NiFi-Registry running with PID ${nifi_registry_pid}.
wait ${nifi_registry_pid}
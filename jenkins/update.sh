#!/bin/bash

git pull
curl \
    -X POST \
    -u ${JENKINS_USER}:${JENKINS_API_TOKEN} \
    "https://jenkins.scheme.org/reload-configuration-as-code/"


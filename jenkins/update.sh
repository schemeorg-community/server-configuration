#!/bin/bash

git pull
curl --netrc-file ${HOME}/.netrc \
   -X POST \
   -G -d @${HOME}/.casc-reload-token \
   https://jenkins.scheme.org/reload-configuration-as-code/


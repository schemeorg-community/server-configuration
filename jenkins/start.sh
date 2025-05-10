#!/bin/bash

if ! type docker compose > /dev/null
then
    docker compose up --build
else
    docker-compose up --build
fi

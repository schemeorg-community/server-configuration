#!/bin/bash

if type docker-compose 2> /dev/null
then
    docker-compose up --build
else
    docker compose up
fi


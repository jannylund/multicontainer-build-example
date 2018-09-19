#!/usr/bin/env bash
set -e
set -o pipefail
set -o xtrace

# Setup variables.
SHA=$(git rev-parse HEAD)
DB_CONTAINER=postgres:latest
DB_NAME=postgres-${SHA}
APP_CONTAINER=jbergknoff/postgresql-client
APP_NAME=client-${SHA}
NET_NAME=somenet-${SHA}

# always trigger cleanup on failure or success.
trap clean 0 1 2 3 6

function clean() {
  if [[ $(docker ps -aq -f name=${DB_NAME}) ]]; then
    docker rm -f ${DB_NAME}
  fi
  if [[ $(docker ps -aq -f name=${APP_NAME}) ]]; then
    docker rm -f ${APP_NAME}
  fi
  if [[ $(docker network ls | grep ${NET_NAME}) ]]; then
    docker network rm ${NET_NAME}
  fi
}

function setup() {
  docker network create ${NET_NAME}
  # start db-container.
  docker run \
    --name ${DB_NAME} \
    --net=${NET_NAME} \
    -d \
    -e POSTGRES_USER=user \
    -e POSTGRES_PASSWORD=pass \
    ${DB_CONTAINER}
  # wait for db-container to startup.
  sleep 2
}

function test {
  # start client, connect to db-container and list databases.
  docker run \
    --name ${APP_NAME} \
    --net=${NET_NAME} \
    ${APP_CONTAINER} \
    postgresql://user:pass@${DB_NAME}:5432 --list
}

setup
test
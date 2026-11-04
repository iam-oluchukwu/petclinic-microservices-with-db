#!/usr/bin/env bash
set -e

echo 'Running Unit Tests on Petclinic Application'

docker run --rm \
  -v "$HOME/.m2:/root/.m2" \
  -v "$PWD:/app" \
  -w /app \
  maven:3.8-openjdk-11 \
  mvn clean test

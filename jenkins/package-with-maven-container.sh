#!/bin/bash
set -e

WORKSPACE="${WORKSPACE:-$(pwd)}"

mkdir -p "$HOME/.m2"

docker run --rm \
  -v "$HOME/.m2:/root/.m2" \
  -v "$WORKSPACE:/app" \
  -w /app \
  maven:3.6-openjdk-11 \
  mvn clean package

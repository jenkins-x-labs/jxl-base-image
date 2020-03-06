#!/bin/bash

echo "promoting the new version ${VERSION} to downstream repositories"

jx step create pr regex --regex "(?m)^FROM gcr.io/jenkinsxio-labs/jxl-base:(?P<version>.*)$" --version ${VERSION} --files Dockerfile --repo https://github.com/jenkins-x-labs/jxl.git

#!/bin/sh

export PROJECT_ID="jenkinsxio-labs"
gcloud builds submit --config cloudbuild.yaml

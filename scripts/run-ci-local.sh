#!/bin/bash

act push -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest \
  --container-options "-v $(pwd)/.env:/home/runner/work/infra-devtools/infra-devtools/.env" \
  -s GITHUB_TOKEN=$ACT_TOKEN
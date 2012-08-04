#!/bin/bash

DEPENDENCIES=(
    'jade'
    'stylus'
    'coffee-script'
    'mkdirp'
    'node-markdown'
    'node-static'
)

npm install ${DEPENDENCIES[@]}

#!/bin/bash

DEPENDENCIES=(
    'jade'
    'coffee-script'
    'stylus'
    'mkdirp'
    'node-markdown'
    'node-static'
)

npm install ${DEPENDENCIES[@]}

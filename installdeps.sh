#!/bin/bash

DEPENDENCIES=(
    'jade'
    'coffee-script'
    'stylus'
    'coffee-script'
    'mkdirp'
    'node-markdown'
    'node-static'
)

npm install ${DEPENDENCIES[@]}

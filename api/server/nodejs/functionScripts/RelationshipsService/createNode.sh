#!/bin/sh
set -x

response=$(curl -X POST http://localhost:5678 -H 'Content-Type: application/json' -d '{{body}}')
echo $response

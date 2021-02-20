#!/bin/bash

# Include config
file='/tmp/data.json'

cat "$file" | jq '.'
# DB settings
# STATUS="$(jq -r '.informationBD[].status' "$file")"
# MESSAGE="$(jq -r '.informationBD[].message' "$file")"

# Show value from variables
# echo $STATUS, $MESSAGE

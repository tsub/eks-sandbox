#!/bin/bash

rootdir="$(dirname "$0")/.."

cd "$rootdir/terraform" || exit 1
terraform init
outputs=$(terraform output)
cd - || exit 1

# Define delimiter
IFS=$'\n'

for output in $outputs; do
    key=$(echo "$output" | cut -d '=' -f 1 | xargs)
    value=$(echo "$output" | cut -d '=' -f 2 | sed 's/\//\\\\\//g' | xargs)

    find "$rootdir/kubernetes" -type f -print0 | xargs -0 -I{} sed -i "s/\${terraform:${key}}/${value}/g" {}
done

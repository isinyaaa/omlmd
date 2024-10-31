#!/usr/bin/env bash

set -e

echo "Preparing venv ..."
poetry build

python -m venv venv
source venv/bin/activate
pip install dist/omlmd-*.whl

echo "Running E2E test for CLI ..."

omlmd push localhost:5001/mmortari/mlartifact:v1 README.md --empty-metadata --plain-http
omlmd push localhost:5001/mmortari/mlartifact:v1 README.md --metadata tests/data/md.json --plain-http

DIR="tmp/a"
omlmd pull localhost:5001/mmortari/mlartifact:v1 -o "$DIR" --plain-http
file_count=$(find "$DIR" -type f | wc -l)
if [ "$file_count" -eq 3 ]; then
    echo "Expected 3 files in $DIR, ok."
else
    echo "Expected 3 files in $DIR, got $file_count, FAIL."
    exit 1
fi

DIR="tmp/b"
omlmd pull localhost:5001/mmortari/mlartifact:v1 -o "$DIR" --media-types "application/vnd.oci.image.layer.v1.tar" --plain-http
file_count=$(find "$DIR" -type f | wc -l)
if [ "$file_count" -eq 1 ]; then
    echo "Expected 1 file in $DIR, ok."
else
    echo "Expected 1 file in $DIR, got $file_count, FAIL."
    exit 1
fi

omlmd get config localhost:5001/mmortari/mlartifact:v1 --plain-http
omlmd crawl localhost:5001/mmortari/mlartifact:v1 localhost:5001/mmortari/mlartifact:v1 --plain-http | jq .
omlmd crawl --plain-http \
    localhost:5001/mmortari/mlartifact:v1 \
    localhost:5001/mmortari/mlartifact:v1 \
    localhost:5001/mmortari/mlartifact:v1 |
    jq "max_by(.config.customProperties.accuracy).reference"

deactivate

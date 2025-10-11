#!/bin/bash

# Script to run coding assignments

echo 'hey' > /tmp/local.txt
cat /tmp/local.txt
aws s3 cp /tmp/local.txt s3://edulensecode/local.txt
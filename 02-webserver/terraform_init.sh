#!/bin/bash
#
# Launch this script to initialize the backend s3
#

terraform init \
  -backend-config="bucket=${TF_VAR_bucket}" \
  -backend-config="key=${TF_VAR_key_webserver}" \
  -backend-config="region=${TF_VAR_region}"

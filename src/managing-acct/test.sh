#!/bin/bash

cd "$(dirname "$0")"

export TF_VAR_armory_s3_bucket=armory-spkr
export TF_VAR_armory_subnet_id=subnet-6c76dd08
export TF_VAR_availability_zones=us-west-2a
export TF_VAR_aws_region=us-west-2
export TF_VAR_key_name=spinnaker-05032016

terraform apply
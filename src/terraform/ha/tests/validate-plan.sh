#!/bin/bash
cd "$(dirname "$0")"

export TF_VAR_aws_region=us-west-2
export TF_VAR_vpc_id=vpc-xxxx
export TF_VAR_s3_bucket=armory-xxxx
export TF_VAR_s3_front50_path_prefix=xxxx
export TF_VAR_armoryspinnaker_subnet_ids=subnet-xxx
export TF_VAR_key_name=xxxx

cd ../
terraform plan
#!/bin/bash
cd "$(dirname "$0")"

set -e

suffix=-v1

# Needed:
export AWS_REGION=us-west-2
export TF_VAR_aws_region=us-west-2
export TF_VAR_vpc_id=vpc-c54befa2
export TF_VAR_s3_bucket=armory-spkr-integration
export TF_VAR_s3_prefix=test${suffix}
export TF_VAR_armoryspinnaker_subnet_ids=subnet-9427e3f3,subnet-98110fee
export TF_VAR_key_name=andrewtest

# Overrides:
export TF_VAR_armoryspinnaker_assume_policy_name=SpinnakerAssumePolicy${suffix}
export TF_VAR_armoryspinnaker_instance_profile_name=SpinnakerInstanceProfile${suffix}
export TF_VAR_armoryspinnaker_managed_profile_name=SpinnakerManagedProfile${suffix}
export TF_VAR_armoryspinnaker_ecr_access_policy_name=SpinnakerECRAccessPolicy${suffix}
export TF_VAR_armoryspinnaker_access_policy_name=SpinnakerAccessPolicy${suffix}
export TF_VAR_armoryspinnaker_s3_access_policy_name=SpinnakerS3AccessPolicy${suffix}
export TF_VAR_armoryspinnaker_internal_elb_name=armoryspinnaker-internal${suffix}
export TF_VAR_armoryspinnaker_external_elb_name=armoryspinnaker-external${suffix}
export TF_VAR_armoryspinnaker_cache_name=armoryspinnaker${suffix}
export TF_VAR_armoryspinnaker_cache_subnet_name=armoryspinnaker-cache-subnet${suffix}
export TF_VAR_armoryspinnaker_external_sg_name=armoryspinnaker-external${suffix}
export TF_VAR_armoryspinnaker_default_sg_name=armoryspinnaker-default${suffix}
export TF_VAR_armoryspinnaker_asg=armoryspinnaker-ha000${suffix}
export TF_VAR_armoryspinnaker_asg_polling=armoryspinnaker-ha-polling-000${suffix}

#export TF_VAR_use_existing_cache=true
#export TF_VAR_existing_cache_endpoint=spinnaker-cache.bfktrz.ng.0001.usw2.cache.amazonaws.com:6379

cd ../
terraform get
terraform plan
terraform apply
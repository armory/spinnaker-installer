#!/bin/bash

cd "$(dirname "$0")"

set -x
result=$(aws sts assume-role \
        --role-arn arn:aws:iam::916699154726:role/StagingAdmin \
        --role-session-name "StagingAdminSession"  \
        --output=text --query 'Credentials.[SecretAccessKey, AccessKeyId, SessionToken]')

export AWS_SECRET_ACCESS_KEY=`echo $result | awk '{print $1}'`
export AWS_ACCESS_KEY_ID=`echo $result | awk '{print $2}'`
export AWS_SESSION_TOKEN=`echo $result | awk '{print $3}'`
exit 1
export TF_VAR_vpc_id=vpc-037ea264
export TF_VAR_armory_s3_bucket=armory-spkr
export TF_VAR_s3_front50_path_prefix=dev-front50
export TF_VAR_armory_subnet_id=subnet-0c14057a
export TF_VAR_availability_zones=us-west-2a
export TF_VAR_aws_region=us-west-2
export TF_VAR_key_name=packager-integration-keypair


export TF_VAR_spinnaker_instance_profile_name=SpinnakerInstanceProfileIntegrationTest
export TF_VAR_spinnaker_managed_profile_name=SpinnakerManagedProfileIntegrationTest
export TF_VAR_spinnaker_access_policy_name=SpinnakerAccessPolicyIntegrationTest
export TF_VAR_spinnaker_web_sg_name=spinnaker-armory-web-integration-test
export TF_VAR_spinnaker_default_sg_name=armory-spinnaker-default-integration-test
export TF_VAR_spinnaker_assume_policy_name=SpinnakerAssumePolicyIntegrationTest
export TF_VAR_spinnaker_s3_access_policy_name=SpinnakerS3AccessPolicyIntegrationTest
export TF_VAR_armory_spinnaker_elb_name=armory-spinnaker-elb-integration
export TF_VAR_armory_spinnaker_cache_subnet_name=armory-spinnaker-cache-integration
export TF_VAR_spinnaker_cache_replication_group_id=test-cache

terraform $1

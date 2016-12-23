from armory import io
import os

KEY_PAIR_NAME="packager-integration-keypair"
def install_armory_spinnaker(vpc_id, subnet_id, key_name):

    env_vars = {
        "TF_VAR_vpc_id": vpc_id,
        "TF_VAR_armory_subnet_id": subnet_id,
        "TF_VAR_armory_s3_bucket": "armory-spkr",
        "TF_VAR_armory_s3_path_prefix": "front50/integration",
        "TF_VAR_availability_zones": "us-west-2a",
        "TF_VAR_aws_region": "us-west-2",
        "TF_VAR_key_name": key_name,
        "TF_VAR_spinnaker_instance_profile_name": "SpinnakerInstanceProfileIntegrationTest",
        "TF_VAR_spinnaker_managed_profile_name": "SpinnakerManagedProfileIntegrationTest",
        "TF_VAR_spinnaker_access_policy_name": "SpinnakerAccessPolicyIntegrationTest",
        "TF_VAR_spinnaker_web_sg_name": "spinnaker-armory-web-integration-test",
        "TF_VAR_spinnaker_default_sg_name": "armory-spinnaker-default-integration-test",
        "TF_VAR_spinnaker_assume_policy_name": "SpinnakerAssumePolicyIntegrationTest",
        "TF_VAR_spinnaker_s3_access_policy_name": "SpinnakerS3AccessPolicyIntegrationTest",
        "TF_VAR_armory_spinnaker_elb_name": "armory-spinnaker-elb-integration",
        "TF_VAR_armory_spinnaker_cache_subnet_name": "armory-spinnaker-cache-integration",
        "TF_VAR_spinnaker_cache_replication_group_id": "test-cache"
    }

    os.environ.update(env_vars)
    result = io.exec_cmd('cd /home/terraform/managing-acct/ && terraform apply')
    io.exec_cmd('cd /home/terraform/managing-acct/ && terraform destroy -force')
    return result

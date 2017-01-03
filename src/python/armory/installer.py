from armory import cmd
import json
import os

KEY_NAME="packager-integration-keypair"


BASE_VARS = {
    "TF_VAR_armory_s3_bucket": "armory-spkr-integration",
    "TF_VAR_armory_s3_path_prefix": "front50/integration",
    "TF_VAR_availability_zones": "us-west-2c",
    "TF_VAR_aws_region": "us-west-2",
    "TF_VAR_key_name": KEY_NAME,
    "TF_VAR_associate_public_ip_address": "true",
}

TEMPLATE_VARS = {
    "TF_VAR_spinnaker_instance_profile_name": "SpinnakerInstanceProfileIntegrationTest",
    "TF_VAR_spinnaker_managed_profile_name": "SpinnakerManagedProfileIntegrationTest",
    "TF_VAR_spinnaker_access_policy_name": "SpinnakerAccessPolicyIntegrationTest",
    "TF_VAR_spinnaker_elb_sg_name": "spinnaker-web-integration-test",
    "TF_VAR_spinnaker_default_sg_name": "armory-spinnaker-default-integration-test",
    "TF_VAR_spinnaker_assume_policy_name": "SpinnakerAssumePolicyIntegrationTest",
    "TF_VAR_spinnaker_s3_access_policy_name": "SpinnakerS3AccessPolicyIntegrationTest",
    "TF_VAR_armory_spinnaker_elb_name": "spinnaker-elb-integration",
    "TF_VAR_armory_spinnaker_cache_sg_name": "spinnaker-cache-sg-integration",
    "TF_VAR_spinnaker_cache_replication_group_id": "integration",
    "TF_VAR_spinnaker_cache_subnet_name": "armoryspkr-integration-subnet",
    "TF_VAR_spinnaker_asg_name": "armory-integration",
    "TF_VAR_spinnaker_ecr_access_policy_name": "SpinnakerECRAccessIntegrationTest"
}

BASE_DIR = "/home/armory/terraform"

def get_env_vars(additional_env, run_id):
    all_env_vars = {}
    all_env_vars.update(BASE_VARS)

    for key in TEMPLATE_VARS:
        all_env_vars[key] = "%s-%s" % (TEMPLATE_VARS[key], run_id)

    all_env_vars.update(additional_env)
    print(all_env_vars)
    return all_env_vars

def find_spinnaker_instance(conn, vpc_id, subnet_id):
    instance = conn.get_all_instances(filters = {
        'instance-state-code': 16,
        'tag:Name': 'armory-spinnaker',
        'subnet-id': subnet_id,
        'vpc-id': vpc_id
    })[0].instances[0]

    return instance

def terraform_exec(run_id, tf_type, tf_command, additional_env={}):
    os.environ.update(get_env_vars(additional_env, run_id))
    result = cmd.exec_cmd('cd %s/%s/ && terraform %s -state=/home/armory/terraform/%s/terraform.tfstate' % (BASE_DIR, tf_type, tf_command, tf_type))
    return result

def create_vpc(run_id, public_key_der):
    public_key_env = { "TF_VAR_public_key": public_key_der }
    result = terraform_exec(run_id, "vpc", "apply", additional_env=public_key_env)
    if result[0] == 0:
        result = terraform_exec(run_id, "vpc", "output -json", additional_env=public_key_env)
        value = json.loads(result[1])["vpc_metadata"]["value"]
        return value["vpc_id"], value["subnet_id"]
    else:
        raise Exception("Problem creating VPC with terraform")

def destroy_vpc(run_id, public_key_der):
    public_key_env = { "TF_VAR_public_key": public_key_der }
    result = terraform_exec(run_id, "vpc", "destroy -force", public_key_env)
    if result[0] != 0: raise Exception("Could not destroy VPC properly")

def destroy_armory_spinnaker(run_id, vpc_id, subnet_id):
    env_vars = {
        "TF_VAR_vpc_id": vpc_id,
        "TF_VAR_armory_subnet_id": subnet_id,
    }
    result = terraform_exec(run_id, "managing-acct", "destroy -force", additional_env=env_vars)
    return result

def install_armory_spinnaker(run_id, vpc_id, subnet_id):
    env_vars = {
        "TF_VAR_vpc_id": vpc_id,
        "TF_VAR_armory_subnet_id": subnet_id,
    }
    result = terraform_exec(run_id, "managing-acct", "apply", additional_env=env_vars)
    if result[0] == 0:
        result = terraform_exec(run_id, "managing-acct", "output -json", additional_env=env_vars)
        value = json.loads(result[1])["spinnaker_metadata"]["value"]
        return value
    return None

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
    "TF_VAR_spinnaker_instance_profile_name": "SpinnakerInstanceProfileIntegrationTest",
    "TF_VAR_spinnaker_managed_profile_name": "SpinnakerManagedProfileIntegrationTest",
    "TF_VAR_spinnaker_access_policy_name": "SpinnakerAccessPolicyIntegrationTest",
    "TF_VAR_spinnaker_elb_sg_name": "spinnaker-web-integration-test",
    "TF_VAR_spinnaker_default_sg_name": "armory-spinnaker-default-integration-test",
    "TF_VAR_spinnaker_assume_policy_name": "SpinnakerAssumePolicyIntegrationTest",
    "TF_VAR_spinnaker_s3_access_policy_name": "SpinnakerS3AccessPolicyIntegrationTest",
    "TF_VAR_armory_spinnaker_elb_name": "spinnaker-elb-integration",
    "TF_VAR_armory_spinnaker_cache_sg_name": "spinnaker-cache-sg-integration",
    "TF_VAR_spinnaker_cache_replication_group_id": "test-cache",
    "TF_VAR_spinnaker_cache_subnet_name": "spinnaker-subnet-group",
    "TF_VAR_spinnaker_asg_name": "armory-integration",
    "TF_VAR_associate_public_ip_address": "true",
    "TF_VAR_spinnaker_ecr_access_policy_name": "SpinnakerECRAccessIntegrationTest"
}

BASE_DIR = "/home/armory/terraform"

def find_spinnaker_instance(conn, vpc_id, subnet_id):
    instance = conn.get_all_instances(filters = {
        'instance-state-code': 16,
        'tag:Name': 'armory-spinnaker',
        'subnet-id': subnet_id,
        'vpc-id': vpc_id
    })[0].instances[0]

    return instance

def terraform_exec(tf_type, tf_command):
    result = cmd.exec_cmd('cd %s/%s/ && terraform %s -state=/home/armory/terraform/%s/terraform.tfstate' % (BASE_DIR, tf_type, tf_command, tf_type))
    return result

def create_vpc(public_key_der):
    os.environ.update({
        "TF_VAR_public_key": public_key_der
    })
    os.environ.update(BASE_VARS)

    result = terraform_exec("vpc", "apply")
    if result[0] == 0:
        result = terraform_exec("vpc", "output -json")
        value = json.loads(result[1])["vpc_metadata"]["value"]
        return value["vpc_id"], value["subnet_id"]
    else:
        raise Exception("Problem creating VPC with terraform")

def destroy_vpc():
    os.environ.update(BASE_VARS)
    result = terraform_exec("vpc", "destroy -force")
    if result[0] != 0: raise Exception("Could not destroy VPC properly")


def destroy_armory_spinnaker(vpc_id, subnet_id):
    env_vars = {
        "TF_VAR_vpc_id": vpc_id,
        "TF_VAR_armory_subnet_id": subnet_id,
    }
    env_vars.update(BASE_VARS)

    os.environ.update(env_vars)
    result = terraform_exec("managing-acct", "destroy -force")
    return result

def install_armory_spinnaker(vpc_id, subnet_id):

    env_vars = {
        "TF_VAR_vpc_id": vpc_id,
        "TF_VAR_armory_subnet_id": subnet_id,
    }
    env_vars.update(BASE_VARS)

    os.environ.update(env_vars)
    result = terraform_exec("managing-acct", "apply")
    if result[0] == 0:
        result = terraform_exec("managing-acct", "output -json")
        value = json.loads(result[1])["spinnaker_metadata"]["value"]
        return value
    return None

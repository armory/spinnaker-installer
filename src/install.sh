#!/usr/bin/env bash
function startup() {
  cat <<EOF

    :::     :::::::::  ::::    ::::   ::::::::  :::::::::  :::   :::
  :+: :+:   :+:    :+: +:+:+: :+:+:+ :+:    :+: :+:    :+: :+:   :+:
 +:+   +:+  +:+    +:+ +:+ +:+:+ +:+ +:+    +:+ +:+    +:+  +:+ +:+
+#++:++#++: +#++:++#:  +#+  +:+  +#+ +#+    +:+ +#++:++#:    +#++:
+#+     +#+ +#+    +#+ +#+       +#+ +#+    +#+ +#+    +#+    +#+
#+#     #+# #+#    #+# #+#       #+# #+#    #+# #+#    #+#    #+#
###     ### ###    ### ###       ###  ########  ###    ###    ###

......................................................................

EOF


  UNINSTALL_ARMORY_SPINNAKER="false"
  set -o pipefail
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
  SOURCE_URL="http://get.armory.io/install/release"
  INSTALLER_PACKAGE_NAME=spinnaker-terraform-SPINNAKER_TERRAFORM_VERSION.tar.gz
  INSTALLER_PACKAGE_URL=${INSTALLER_PACKAGE_URL:-${SOURCE_URL}/${INSTALLER_PACKAGE_NAME}}
  TMP_PATH="${HOME}/tmp/armory"
  TMP_PACKAGE_PATH="${TMP_PATH}/${INSTALLER_PACKAGE_NAME}"
  MP_FILE="${TMP_PATH}/armory-env.tmp"
}

function describe_installer() {
  echo "
  This installer will launch Spinnaker inside your AWS account.

  The following AWS resources are required:
    - AWS Shared Credentials File
    - Existing target VPC & Subnet
    - S3 Bucket to place terraform state & Spinnaker backend store

  The following AWS resources will be created:
    - Autoscaling group and launch configuration
    - Elastic Load Balancer
    - Security group for the ELB
    - Security group for the Spinnaker stack
    - Elastic Cache (Redis)
    - IAM Role for Spinnaker instances
    - IAM Role for Spinnaker managed account
    - IAM Policy Spinnaker S3 Access
    - IAM Policy Spinnaker assume role permissions
    - IAM Policy Spinnaker ECR read access


Need help, advice, or just want to say hello during the installation?
Chat with our eng. team at http://go.Armory.io/chat.
One customer called us “ridiculously responsive.”  Hopefully we can be the same for you!

Press 'Enter' key to continue. Ctrl+C to quit.
"
  read
}

function error() {
  echo >&2 "Oops that didn't work.  Visit http://go.armory.io/chat to chat with us and we can help"
  echo >&2 "ERROR: $1"
  echo >&2 "Aborting."
  exit 1;
}

function mac_warning() {
  uname -a|grep Darwin
  if [[ "$?" -eq "0" ]]; then
    echo "WARNING: You're on a version of Mac OSX.  Your Docker VM might be"
    echo "out of sync with your system clock causing AWS signature issues. "
    echo "If you experience an error please retry restarting your docker daemon "
    echo
  fi
}
function docker_error() {
  error_message=$1
  uname -a|grep Linux
  if [[ "$?" -eq "0" ]]; then
    linux_msg="${error_message}
NOTE: If you've installed Docker as a package, you may need to
configure permissions to allow you to run Docker as a non-root
user, or run the installer as root.
Ref: https://docs.docker.com/engine/installation/linux/linux-postinstall/"
    error "$linux_msg"
  else
    error "$error_message"
  fi
}

function look_for_curl() {
  type curl >/dev/null 2>&1 || { error "I require curl but it's not installed."; }
}
function look_for_tar() {
  type tar >/dev/null 2>&1 || { error "I require tar but it's not installed."; }
}

function look_for_docker() {
  type docker >/dev/null 2>&1 || { docker_error "I require docker but it's not installed."; }
  docker ps >/dev/null 2>&1 || { docker_error "Docker daemon is not running."; }
  mac_warning
}

function look_for_aws() {
  type aws >/dev/null 2>&1 || { error "I require aws but it's not installed. Ref: http://docs.aws.amazon.com/cli/latest/userguide/installing.html"; }
}

function run_terraform() {
  docker run -i -t \
    --env-file=$MP_FILE \
    --workdir=/data \
    -v ${TMP_PATH}:/data \
    hashicorp/terraform:0.8.4 \
    $@
}

function create_tmp_space() {
  rm -r ${TMP_PATH} || true
  mkdir -p ${TMP_PATH}
}

function validate_s3_bucket() {
  local bucket=${1}
  aws --profile ${AWS_PROFILE} --region ${TF_VAR_aws_region} s3 ls s3://${bucket} &> /dev/null
  local result=$?
  if [ "$result" != "0" ]; then
    echo "Could not list bucket '${1}' using profile '${AWS_PROFILE}'. Are you sure you have permissions?"
    return $result
  fi

  local resp=$(aws --profile ${AWS_PROFILE} --region ${TF_VAR_aws_region} s3api get-bucket-location --bucket ${bucket})
  # This is a special case for us-east-1. The AWS API returns null for legacy reasons.
  if [ "${TF_VAR_aws_region}" == "us-east-1" ]; then
    echo $resp | grep None &> /dev/null || {
      echo "Bucket ${bucket} is not in ${TF_VAR_aws_region}"
      return 1
    }
  else
    echo $resp | grep ${TF_VAR_aws_region} &> /dev/null || {
      echo "Bucket ${bucket} is not in ${TF_VAR_aws_region}"
      return 1
    }
  fi

  echo "Valid S3 Bucket selected."
  return 0
}

function list_s3_bucket() {
  echo "Available S3 buckets (all regions):"
  aws --profile ${AWS_PROFILE} --region ${TF_VAR_aws_region} s3 ls
}

function validate_vpc() {
  local vpc=${1}
  aws --profile ${AWS_PROFILE} --region ${TF_VAR_aws_region} ec2 describe-vpcs --vpc-ids ${vpc} &> /dev/null
  local result=$?
  if [ "$result" != "0" ]; then
    echo "Could not find '${vpc}' in ${TF_VAR_aws_region} using profile '${AWS_PROFILE}'. Please check that it exists and you have permission."
    return $result
  fi
  local vpc_cidr=$(aws --profile ${AWS_PROFILE} --region ${TF_VAR_aws_region} ec2 describe-vpcs --vpc-ids ${vpc} --query 'Vpcs[0].{cidr:CidrBlock}' --output text)
  # AWS netmasks have at minimum 16 significant bits, so we can match on the
  # first two bytes of the cidr to make sure there's no overlap.
  if [[ ${vpc_cidr} == 172.17.* ]]; then
    echo "VPC CIDR block (${vpc_cidr}) conflicts with the Docker bridge network at 172.17.0.0/16"
    return 1
  fi
  if [[ ${vpc_cidr} == 172.18.* ]]; then
    echo "VPC CIDR block (${vpc_cidr}) conflicts with the docker-compose network at 172.18.0.0/16"
    return 1
  fi
  return $result
}

function validate_subnet() {
  local subnets=$(echo $1 | tr ',' ' ')
  aws --profile ${AWS_PROFILE} --region ${TF_VAR_aws_region} ec2 describe-subnets --filters "Name=vpc-id,Values=${TF_VAR_vpc_id}" --subnet-ids ${subnet} &> /dev/null
  local result=$?
  if [ "$result" == "0" ]; then
    echo "Valid Subnet selected."
  else
    echo "Could not find subnet '${subnet}' in ${TF_VAR_vpc_id} using profile 'AWS_PROFILE' in ${TF_VAR_aws_region}. Please check that it exists and you have permission."
  fi
  return $result
}

function validate_keypair() {
  local keypair=${1}
  aws --profile ${AWS_PROFILE} --region ${TF_VAR_aws_region} ec2 describe-key-pairs --key-names ${keypair} &> /dev/null
  local result=$?
  if [ "$result" == "0" ]; then
    echo "Valid key-pair selected."
  else
    echo "Could not find '${keypair}' in ${TF_VAR_aws_region} using profile '${AWS_PROFILE}'. Please check that it exists and you have permission."
  fi
  return $result
}

function validate_public_elb() {
  local option=${1}
  if [ "${option}" == "y" ] || [ "${option}" == "n" ] ; then
    if [ "${option}" == "y" ] ; then
      echo "User-facing load balancer will be accessible from the internet."
    else
      echo "No load balancers will be directly accessible from the internet."
    fi
    return 0
  fi
  echo "You must answer 'y' or 'n'."
  return 1
}

function validate_mode() {
  local mode=${1}
  if [ "${mode}" == "ha" ] || [ "${mode}" == "stand-alone" ] ; then
    echo "Valid mode selected."
    return 0
  fi
  echo "Invalid mode selected."
  return 1
}

function validate_profile() {
  local profile=${1}
  aws configure get ${profile}.aws_access_key_id &> /dev/null
  local result=$?
  if [ "$result" == "0" ]; then
    echo "Valid Profile selected."
  else
    echo "Could not find access key id for profile '${profile}'. Are you sure there is a profile with that name in your AWS credentials file?"
  fi
  return $result
}

function validate_region() {
  local region=${1}
  local regions=("us-west-1" "us-west-2" "us-east-1" "eu-central-1" "eu-west-1")
  for r in ${regions[@]}; do
    if [ "${region}" == "${r}" ] ; then
      echo "Valid region selected."
      return 0
    fi
  done
  echo "Armory Spinnaker is only available in:"
  for r in ${regions[@]}; do
    echo "  - ${r}"
  done
  echo "Visit http://go.armory.io/chat to let us know where else you'd like Armory Spinnaker."
  return 1
}

function get_var() {
  local text=$1
  local var_name="${2}"
  local val_func=${3}
  local val_list=${4}
  if [ -z ${!var_name} ]; then
    [ ! -z "$val_list" ] && $val_list
    echo -n "${text}"
    read value
    if [ -z "${value}" ]; then
      echo "This value can not be blank."
      get_var "$1" $2 $3
    elif [ ! -z "$val_func" ] && ! $val_func ${value}; then
      get_var "$1" $2 $3
    else
      export ${var_name}=${value}
    fi
  fi
}

function set_aws_vars() {
  role_arn=$(aws configure get ${AWS_PROFILE}.role_arn)
  if [[ "${role_arn}" == "" ]]; then
    export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
  else
    #for more info on setting up your credentials file go here: http://docs.aws.amazon.com/cli/latest/topic/config-vars.html#using-aws-iam-roles
    source_profile=$(aws configure get ${AWS_PROFILE}.source_profile)
    temp_session_data=$(aws sts assume-role --role-arn ${role_arn} --role-session-name armory-spinnaker --profile ${source_profile} --output text)
    export AWS_ACCESS_KEY_ID=$(echo ${temp_session_data} | awk '{print $5}')
    export AWS_SECRET_ACCESS_KEY=$(echo ${temp_session_data} | awk '{print $7}')
    export AWS_SESSION_TOKEN=$(echo ${temp_session_data} | awk '{print $8}')
  fi
  export AWS_REGION=${TF_VAR_aws_region}
}

function prompt_user() {
  use_env_file='n'
  if [ -f ${MP_FILE} ]; then
    echo "Found an existing env file: ${MP_FILE}."
    echo -n "Would you like to continue to use the responses from your last run? [y/n]:"
    read use_env_file
  fi
  if [[ "${use_env_file}" == 'n' ]]; then
    get_var "Would you like to install Armory Spinnaker in a high availablity('ha') or development('stand-alone') configuration? [stand-alone|ha]: " TF_VAR_deploy_configuration validate_mode
    get_var "Enter your AWS Profile [e.g. devprofile]: " AWS_PROFILE validate_profile
    get_var "Enter an AWS Region. Spinnaker will be installed inside this region. [e.g. us-west-2]: " TF_VAR_aws_region validate_region
    get_var "Enter an already created S3 bucket to use for persisting Spinnaker's data, this bucket must be in the specified region [e.g. examplebucket]: " TF_VAR_s3_bucket validate_s3_bucket list_s3_bucket
    get_var "Enter S3 path prefix to use within the bucket [e.g. armory/config]: " TF_VAR_s3_prefix
    get_var "Enter a VPC ID. Spinnaker will be installed inside this VPC. [e.g. vpc-7762cd13]: " TF_VAR_vpc_id validate_vpc
    get_var "Enter Subnet ID(s). Spinnaker will be installed inside this Subnet. Subnets cannot be in the same AZ [e.g. subnet-8f5d43d6,subnet-1234abcd]: " TF_VAR_armoryspinnaker_subnet_ids validate_subnet
    get_var "Enter a Key Pair name already set up with AWS/EC2. Spinnaker will be created using this key. [e.g. default-keypair]: " TF_VAR_key_name validate_keypair
    get_var "Should the UI be Internet Facing? [y/n]: " TF_VAR_armoryspinnaker_public_elb validate_public_elb

    create_tmp_space
    set_aws_vars
    save_user_responses
  fi

  download_tf_templates # always download the newest terraform from script
}

function save_user_responses() {
  echo "Saving to ${MP_FILE}..."
  # we have to do this to make sure to not put this bash into
  # environment file
  unset BASH_EXECUTION_STRING
  unset SUDO_COMMAND
  local_env=$(set -o posix ; set | grep -E "TF_VAR|AWS")
  echo "$local_env" >> $MP_FILE
}

function download_tf_templates() {
  echo "Downloading terraform template files..."
  echo "curl --output ${TMP_PACKAGE_PATH} ${INSTALLER_PACKAGE_URL}"
  curl --output ${TMP_PACKAGE_PATH} ${INSTALLER_PACKAGE_URL} 2>>/dev/null || { error "Could not download."; }
  tar xvfz ${TMP_PACKAGE_PATH} -C ${TMP_PATH} || { error "Could not untar package."; }
}

function clean_terraform() {
  run_terraform "destroy" $1
}

function fetch_configuration() {
  source ${MP_FILE}
  run_terraform "remote config -backend=S3 \
    -backend-config=bucket=${TF_VAR_s3_bucket} \
    -backend-config=key=${TF_VAR_s3_prefix}/terraform/terraform.tfstate \
    -backend-config=region=${TF_VAR_aws_region} \
    -pull=true"

  run_terraform "get" "./${TF_VAR_deploy_configuration}"
}

function create_spinnaker_stack() {
  run_terraform "apply" "./${TF_VAR_deploy_configuration}" || {
    echo "Terraform error. Cleaning up partial infrastruction."
    clean_terraform "./${TF_VAR_deploy_configuration}"
    error "Terraform error."
  }
}

function delete_spinnaker_stack() {
  echo "Uninstalling..."
  clean_terraform "./${TF_VAR_deploy_configuration}"
}

function save_configuration() {
  run_terraform "remote push"
}

function wait_for_spinnaker() {
  echo "All your resources have been created."
  echo "Log into your AWS console and find your UI ELB URL"
  echo "Need help, advice, or just want to say hello during the installation?"
  echo "You can chat with our team at ${BLUE}http://go.armory.io/chat${NC}"
  exit 0
}

function main() {
  startup
  if [[ ${UNINSTALL_ARMORY_SPINNAKER} == "uninstall" ]] ; then
    fetch_configuration
    delete_spinnaker_stack
  else
    describe_installer
    look_for_curl
    look_for_tar
    look_for_docker
    look_for_aws
    prompt_user
    fetch_configuration
    create_spinnaker_stack
    wait_for_spinnaker
  fi
  save_configuration
}

main

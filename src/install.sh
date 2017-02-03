#!/usr/bin/env bash
cat << EOF

    :::     :::::::::  ::::    ::::   ::::::::  :::::::::  :::   :::
  :+: :+:   :+:    :+: +:+:+: :+:+:+ :+:    :+: :+:    :+: :+:   :+:
 +:+   +:+  +:+    +:+ +:+ +:+:+ +:+ +:+    +:+ +:+    +:+  +:+ +:+
+#++:++#++: +#++:++#:  +#+  +:+  +#+ +#+    +:+ +#++:++#:    +#++:
+#+     +#+ +#+    +#+ +#+       +#+ +#+    +#+ +#+    +#+    +#+
#+#     #+# #+#    #+# #+#       #+# #+#    #+# #+#    #+#    #+#
###     ### ###    ### ###       ###  ########  ###    ###    ###

......................................................................

EOF

set -o pipefail
BLUE='\033[0;34m'
NC='\033[0m' # No Color
SOURCE_URL="http://get.armory.io/install/release"
INSTALLER_PACKAGE_NAME="spinnaker-terraform-3040ee3.tar.gz"
TMP_PATH=${HOME}/tmp/armory
TMP_PACKAGE_PATH=${TMP_PATH}/${INSTALLER_PACKAGE_NAME}
MP_FILE=${TMP_PATH}/armory-env.tmp
function describe_installer() {
  cat <<EOF
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
Press 'Enter' key to continue. Ctrl+c to quit.
EOF
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

function look_for_docker() {
  type docker >/dev/null 2>&1 || { error "I require docker but it's not installed."; }
  docker ps >/dev/null 2>&1 || { error "Docker deamon is not running."; }
  mac_warning
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

function get_var() {
  local text=$1
  local var_name="${2}"
  if [ -z ${!var_name} ]; then
    echo -n "${text}"
    read value
    if [ -z "${value}" ]; then
      echo "This value can not be blank."
      get_var $1 $2
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
}

function prompt_user() {
  if [ -f ${MP_FILE} ]; then
    echo "Found an existing env file: ${MP_FILE}."
    echo -n "Would you like to continue to use the responses from your last run? [y/n]:"
    read use_env_file
  fi
  if [[ "${use_env_file}" == 'n' ]]; then
    get_var "Would you like to install Armory Spinnaker in a high availablity('ha') or development('stand-alone') configuration? [stand-alone|ha]:" TF_VAR_deploy_configuration
    get_var "Enter your AWS Profile [e.g. devprofile]: " AWS_PROFILE
    get_var "Enter an already created S3 bucket to use for persisting Spinnaker's data, [e.g. examplebucket]: " TF_VAR_s3_bucket
    get_var "Enter S3 path prefix to use within the bucket [e.g. armory/config]: " TF_VAR_s3_prefix
    get_var "Enter an AWS Region. Spinnaker will be installed inside this region. [e.g. us-west-2]: " TF_VAR_aws_region
    get_var "Enter a VPC ID. Spinnaker will be installed inside this VPC. [e.g. vpc-7762cd13]: " TF_VAR_vpc_id
    get_var "Enter Subnet ID(s). Spinnaker will be installed inside this Subnet. Subnets cannot be in the same AZ [e.g. subnet-8f5d43d6,subnet-1234abcd]: " TF_VAR_armoryspinnaker_subnet_ids
    get_var "Enter a Key Pair name already set up with AWS/EC2. Spinnaker will be created using this key. [e.g. default-keypair]: " TF_VAR_key_name

    create_tmp_space
    set_aws_vars
    save_user_responses
    download_tf_templates
  fi
}

function save_user_responses() {
  echo "Saving to ${MP_FILE}..."
  # we have to do this to make sure to not put this bash into
  # environment file
  unset BASH_EXECUTION_STRING
  local_env=$(set -o posix ; set | grep -E "TF_VAR|AWS")
  echo "$local_env" >> $MP_FILE
}

function download_tf_templates() {
  echo "Downloading terraform template files..."
  curl --output ${TMP_PACKAGE_PATH} "${SOURCE_URL}/${INSTALLER_PACKAGE_NAME}" 2>>/dev/null || { error "Could not download."; }
  tar xvfz ${TMP_PACKAGE_PATH} -C ${TMP_PATH} || { error "Could not untar package."; }
}

function clean_terraform() {
  run_terraform "destroy" $1
}

function create_spinnaker_stack() {
  source ${MP_FILE}
  run_terraform "remote config -backend=S3 \
    -backend-config=bucket=${TF_VAR_s3_bucket} \
    -backend-config=key=${TF_VAR_s3_prefix}/terraform/terraform.tfstate \
    -backend-config=region=${TF_VAR_aws_region} \
    -pull=true"

  run_terraform "get" "./${TF_VAR_deploy_configuration}"
  run_terraform "apply" "./${TF_VAR_deploy_configuration}" || {
    echo "Terraform error. Cleaning up partial infrastruction."
    clean_terraform "./${TF_VAR_deploy_configuration}"
    error "Terraform error."
  }
  run_terraform "remote push"
}

function wait_for_spinnaker() {
  echo "All your resources have been created."
  echo "Log into your AWS console and find your external ELB URL"
  echo "Need help, advice, or just want to say hello during the installation?"
  echo "You can chat with our team at ${BLUE}http://go.armory.io/chat${NC}"
  exit 0
}

function main() {
  describe_installer
  look_for_docker
  prompt_user
  create_spinnaker_stack
  wait_for_spinnaker
}

main

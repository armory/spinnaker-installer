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

set -o errexit
set -o pipefail

SOURCE_URL="http://get.armory.io/${PREFIX}"
INSTALLER_PACKAGE_NAME="armory-spinnaker-installer.tar.gz"
TMP_PATH=/tmp/armory
TMP_PACKAGE_PATH=${TMP_PATH}/${INSTALLER_PACKAGE_NAME}

function describe_installer() {
  cat <<EOF
  This installer will launch Spinnaker inside your AWS account.

  The following AWS resources are required:
    - VPC
    - Subnet
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

Press 'Enter' key to continue. Ctrl+c to quit.
EOF
  read
}

function mac_warning() {
  uname -a|grep Darwin
  if [[ "$?" -eq "0" ]]; then
    echo "WARNING: You're on a version of Mac OSX.  Your Docker VM might be"
    echo "out of sync with your system clock causing AWS signature issues. "
    echo "If you experience an error please retry restarting your docker daemon"
  fi
}

function look_for_docker() {
  type docker >/dev/null 2>&1 || { echo >&2 "ERROR: I require docker but it's not installed.  Aborting."; exit 1; }
  mac_warning
}

function run_terraform() {
  docker run -i -t \
    --env-file=$mpfile \
    --workdir=/data \
    -v ${TMP_PATH}:/data \
    hashicorp/terraform:light \
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

function prompt_user() {
  get_var "Enter AWS Secret Access Key[e.g. AKIAIOUF8KK9KELEQSFA]:" AWS_ACCESS_KEY_ID
  get_var "Enter AWS Secret Access Key[e.g. klBmdoR7M+ULWL3OB828Vb7BbcwQdF+4ZZOlHGk6]:" AWS_SECRET_ACCESS_KEY
  get_var "Enter S3 bucket to use for persisting Spinnaker's data[e.g. examplebucket]:" TF_VAR_armory_s3_bucket
  get_var "Enter S3 path prefix to use within the bucket [e.g. armory/config]:" TF_VAR_s3_front50_path_prefix
  get_var "Enter an AWS Region. Spinnaker will be installed inside this region. [e.g. us-west-2]:" TF_VAR_aws_region
  get_var "Enter one or more AWS availablity zones. Spinnaker will be replicated within those zones. [e.g. us-west-2a,us-west2b]:" TF_VAR_availability_zones
  get_var "Enter a VPC ID. Spinnaker will be installed inside this VPC. [e.g. vpc-7762cd13]:" TF_VAR_vpc_id
  get_var "Enter a Subnet ID. Spinnaker will be installed inside this Subnet. [e.g. subnet-8f5d43d6]:" TF_VAR_armory_subnet_id
  get_var "Enter a Key Pair name already set up with AWS/EC2. Spinnaker will be created using this key. [e.g. default-keypair]" TF_VAR_key_name
}

function save_user_responses() {
  mpfile=/tmp/armory/armory-env.tmp
  echo "Saving to ${mpfile}..."
  # we have to do this to make sure to not put this bash into
  # environment file
  unset BASH_EXECUTION_STRIN  G
  local_env=$(set -o posix ; set | grep -E "TF_VAR|AWS")
  echo "$local_env" >> $mpfile
}

function download_tf_templates() {
  files="elb.tf instances.tf provider.tf redis.tf roles.tf sg.tf variables.tf userdata.sh"
  echo "Downloading terraform template files..."
  curl --output ${TMP_PACKAGE_PATH} "${SOURCE_URL}/${INSTALLER_PACKAGE_NAME}" 2>>/dev/null
  tar xvfz ${TMP_PACKAGE_PATH} -C ${TMP_PATH}
}

function create_spinnaker_stack() {
  run_terraform "remote config -backend=S3 \
    -backend-config=bucket=${TF_VAR_armory_s3_bucket} \
    -backend-config=key=${TF_VAR_armory_s3_path_prefix}/terraform/terraform.tfstate \
    -backend-config=region=${TF_VAR_aws_region} \
    -pull=true"

  #run_terraform "apply" "./managing-acct"
  #run_terraform "remote push"
}

function wait_for_spinnaker() {
  local terraform_output=$(run_terraform "output" | tr -d '\n\r')
  local spinnaker_host=$(expr "${terraform_output}" : ".* spinnaker_url = \(.*\)}")
  echo "Waiting for ${spinnaker_host} to become available."
  spinnaker_url="http://${spinnaker_host}"

  for i in {1..420}; do
    echo -n "."
    #we set +e so we don't error out when curl doesn't return 0
    set +e
    curl_result=$(curl -s --connect-timeout 2 ${spinnaker_url} &2>>/dev/null)
    if [[ ${curl_result} != "" ]];then
      echo ""
      echo "Your Armory Spinnaker instance is up! Check it out: ${spinnaker_url}"
      exit 0
    fi
    set -e
    sleep 1
  done
  echo ""
  echo "Couldn't connect to ${spinnaker_url}:9000. It is possible that partial installation has occurred. You probably have AWS resources created through this process that need to be cleaned up."
  exit 1
}

function main() {
  describe_installer
  look_for_docker
  prompt_user
  create_tmp_space
  save_user_responses
  download_tf_templates
  create_spinnaker_stack
  wait_for_spinnaker
}

main

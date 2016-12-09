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

function look_for_docker() {
  type docker >/dev/null 2>&1 || { echo >&2 "ERROR: I require docker but it's not installed.  Aborting."; exit 1; }
}

function get_vars() {

  if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -n "Enter AWS Secret Access Key[e.g. AKIAIOUF8KK9KEQEQSFA]:"
    read AWS_ACCESS_KEY_ID
  fi
  if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -n "Enter AWS Secret Access Key[e.g. klBmdoR7M+UQWL3OB828Vb7BbcwQdF+4ZZOlHGk6]:"
    read AWS_SECRET_ACCESS_KEY
  fi
  if [ -z "${TF_VAR_armory_s3_bucket}" ]; then
    echo -n "Enter S3 bucket[e.g. examplebucket]:"
    read TF_VAR_armory_s3_bucket
  fi

  if [ -z "${TF_VAR_armory_s3_path_prefix}" ]; then
    echo -n "Enter S3 path prefix [e.g. armory/config]:"
    read TF_VAR_armory_s3_path_prefix
  fi

  if [ -z "${TF_VAR_armory_s3_config_path}"]; then
    TF_VAR_armory_s3_config_path="s3://${TF_VAR_armory_s3_bucket}/${TF_VAR_armory_s3_path_prefix}/config"
  fi

  echo "getting vars..."
  rm -r /tmp/armory/ || true
  mkdir -p /tmp/armory/
  mpfile=$(mktemp /tmp/armory/armory-env.tmp)
  echo "saving armory environment variables: $mpfile"

  # we have to do this to make sure to not put this bar into
  # environment file
  unset BASH_EXECUTION_STRING
  local_env=$(set -o posix ; set | grep -E "TF_VAR|AWS")
  echo "$local_env" >> $mpfile

  echo "Downloading template files..."
  curl --output "/tmp/armory/armory-spinnaker.tf" "${SOURCE_URL}/armory-spinnaker.tf"
  echo curl --output "/tmp/armory/userdata.sh" "${SOURCE_URL}/userdata.sh"
  curl --output "/tmp/armory/userdata.sh" "${SOURCE_URL}/userdata.sh"
}

function run_terraform() {
  docker run -i -t \
    --env-file=$mpfile \
    --workdir=/data \
    -v /tmp/armory:/data \
    hashicorp/terraform:light \
    $1
}

function mac_warning() {
  uname -a|grep Darwin
  if [[ "$?" -eq "0" ]]; then
    echo "WARN: You're on a version of Mac OSX.  Your Docker VM might be"
    echo "out of sync with your system clock causing AWS signature issues. "
    echo "If you experience an error please retry restarting your docker daemon"
  fi
}

echo "Beginning Install for Armory Spinnaker..."
look_for_docker
get_vars
mac_warning
run_terraform "remote config -backend=S3 \
  -backend-config=bucket=${TF_VAR_armory_s3_bucket} \
  -backend-config=key=${TF_VAR_armory_s3_path_prefix}/terraform/terraform.tfstate \
  -backend-config=region=${TF_VAR_aws_region} \
  -pull=true"
run_terraform "apply"
run_terraform "remote push"
ip_result=$(run_terraform "output spinnaker_instance_dns" | tr -d '\r')
spinnaker_host=http://${ip_result}:9000
echo "Your Armory dashboard is still initializing, please wait 4-5 minutes."
echo "Waiting for ${spinnaker_host} to become available."
for i in {1..420}; do
  echo -n "."
  #we set +e so we don't error out when curl doesn't return 0
  set +e
  curl_result=$(curl -s --connect-timeout 2 ${spinnaker_host})
  if [[ ${curl_result} != "" ]];then
    echo ""
    echo "Your Armory Spinnaker instance is up!  You can find it here: ${spinnaker_host}"
    exit 0
  fi
  set -e
  sleep 1
done

echo ""
echo "Couldn't connect to ${ip_result}:9000, please makes sure you have connectivity, security groups and networking is verified"
exit 1

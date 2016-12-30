#!/bin/bash
#wait for other services to come up
echo "Sleeping for 20 seconds before executing scripts..."
sleep 20

cat <<EOT > /etc/default/armory
ARMORY_S3_BUCKET=${s3_bucket}
ARMORY_S3_FRONT50_PATH_PREFIX=${s3_front50_path_prefix}
AWS_REGION=${aws_region}
API_HOST=http://${elb_hostname}:8084
DECK_HOST=0.0.0.0
DECK_PORT=9000
AUTH_ENABLED=false
SERVER_ADDRESS=0.0.0.0
SPRING_CONFIG_LOCATION=/opt/spinnaker/config/
REDIS_HOST=${redis_host}
EOT

service armory-spinnaker start

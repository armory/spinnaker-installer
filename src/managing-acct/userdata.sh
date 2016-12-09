#!/bin/bash
#wait for other services to come up
echo "Sleeping for 20 seconds before executing scripts..."
sleep 20
#this is just a hack becase the image (AMI) is created with an overflow, i think
hostname=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
public_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cat <<EOT > /etc/default/armory
ARMORY_S3_BUCKET=${s3_bucket}
ARMORY_S3_FRONT50_PATH_PREFIX=${s3_front50_path_prefix}
AWS_REGION=${aws_region}
HOSTNAME=$hostname
PUBLIC_IP=$public_ip
API_HOST=http://$hostname:8084
DECK_HOST=0.0.0.0
DECK_PORT=9000
AUTH_ENABLED=false
SERVER_ADDRESS=0.0.0.0
SPRING_CONFIG_LOCATION=/opt/spinnaker/config/
EOT

source /etc/default/armory

sudo docker-compose -f /application/compose/docker-compose.yml up -d

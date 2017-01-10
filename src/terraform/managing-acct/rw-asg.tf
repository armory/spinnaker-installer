data "template_file" "armory_spinnaker_rw_ud" {
  template = <<EOF
#!/bin/bash
#wait for other services to come up
echo "Sleeping for 20 seconds before executing scripts..."
sleep 20

cat <<EOT > /etc/default/armory-spinnaker
#!/bin/bash
# Used to determine what services to start on the instance.
export ARMORY_SPINNAKER_MODE=ha
EOT

cat <<EOT > /opt/spinnaker/compose/environment
# Used by Spinnaker/front50 to persist pipelines:
ARMORY_S3_BUCKET=$${s3_bucket}
ARMORY_S3_FRONT50_PATH_PREFIX=$${s3_front50_path_prefix}
SPINNAKER_AWS_DEFAULT_REGION=$${aws_region}
# Gate URL used by Deck:
API_HOST=http://$${external_elb}:8084
# Used by the Spinnaker subservices to communicate internally:
INTERNAL_SERVICES_DNS_NAME=$${internal_elb}
AUTH_ENABLED=false
SPRING_CONFIG_LOCATION=/opt/spinnaker/config/
REDIS_HOST=$${redis_host}
EOT

service armory-spinnaker restart
EOF

  vars {
    s3_bucket               = "${var.armory_s3_bucket}"
    s3_front50_path_prefix  = "${var.s3_front50_path_prefix}"
    aws_region              = "${var.aws_region}"
    redis_host              = "${aws_elasticache_replication_group.armory-spinnaker-cache.primary_endpoint_address}"
    external_elb            = "${aws_elb.armory_spinnaker_external_elb.dns_name}"
    internal_elb            = "${aws_elb.armory_spinnaker_internal_elb.dns_name}"
  }
}

module "rw-asg" {
  source = "./asg"
  asg_name = "armoryspinnaker-ha-poller"
  asg_size_min = 1
  asg_size_max = 1
  asg_size_desired = 1
  user_date = "${data.template_file.armory_spinnaker_rw_ud.rendered}"
  load_balancers = ["${aws_elb.armory_spinnaker_external_elb.dns_name}", "${aws_elb.armory_spinnaker_internal_elb.dns_name}"]
}

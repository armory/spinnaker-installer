output "spinnaker_metadata" {
    value = {
      spinnaker_url   = "${aws_elb.armory_spinnaker_external_elb.dns_name}"
      cache_endpoint  = "${aws_elasticache_replication_group.armory-spinnaker-cache.primary_endpoint_address}"
    }
}

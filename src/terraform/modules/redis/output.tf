output "primary_endpoint_address" {
    value = "${aws_elasticache_replication_group.armoryspinnaker-cache.primary_endpoint_address}"
}
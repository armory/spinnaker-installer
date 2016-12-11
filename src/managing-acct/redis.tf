resource "aws_elasticache_replication_group" "armory-spinnaker-cache" {
  replication_group_id          = "spinnaker-cache"
  replication_group_description = "Spinnaker's cache"
  number_cache_clusters         = "2"
  node_type                     = "cache.t2.small"
  engine_version                = "3.2.4"
  security_group_ids            = ["${aws_security_group.armory_spinnaker_default.id}"]
  maintenance_window            = "sun:02:30-sun:03:30"
  port                          = "6379"

  tags {
    Name                        = "armory-spinnaker-cache"
  }
}

output "armory-spinnaker-cache-endpoint" {
    value = "${aws_elasticache_replication_group.armory-spinnaker-cache.primary_endpoint_address}"
}
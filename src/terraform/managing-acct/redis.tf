resource "aws_elasticache_subnet_group" "armory-spinnaker-cache-subnet" {
    name = "${var.spinnaker_cache_subnet_name}"
    subnet_ids = ["${var.armory_subnet_id}"]
}

resource "aws_elasticache_replication_group" "armory-spinnaker-cache" {
  replication_group_id          = "${var.spinnaker_cache_replication_group_id}"
  replication_group_description = "Spinnaker's cache"
  number_cache_clusters         = "2"
  node_type                     = "cache.t2.small"
  engine_version                = "3.2.4"
  security_group_ids            = ["${aws_security_group.armory_spinnaker_default.id}"]
  subnet_group_name             = "${aws_elasticache_subnet_group.armory-spinnaker-cache-subnet.name}"
  maintenance_window            = "sun:02:30-sun:03:30"
  port                          = "6379"

  tags {
    Name                        = "armory-spinnaker-cache"
  }
}

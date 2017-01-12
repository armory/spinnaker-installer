
resource "aws_elasticache_subnet_group" "armory-spinnaker-cache-subnet" {
    name = "${var.cache_subnet_name}"
    subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_elasticache_replication_group" "armoryspinnaker-cache" {
  replication_group_id          = "${var.cache_name}"
  replication_group_description = "Spinnaker's cache"
  number_cache_clusters         = "2"
  node_type                     = "cache.t2.small"
  engine_version                = "3.2.4"
  security_group_ids            = ["${var.default_sg_id}"]
  subnet_group_name             = "${aws_elasticache_subnet_group.armory-spinnaker-cache-subnet.name}"
  maintenance_window            = "sun:02:30-sun:03:30"
  port                          = "6379"

  tags {
    Name                        = "${var.cache_name}"
  }
}

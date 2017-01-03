resource "aws_vpc" "main" {
    cidr_block = "10.1.0.0/16"

    tags {
        Name = "Integration Test VPC"
    }
}

resource "aws_key_pair" "deployer" {
  key_name = "${var.key_name}"
  public_key = "${var.public_key}"
}

resource "aws_route_table" "main_route" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags {
        Name = "main route for integration test"
    }
}

resource "aws_main_route_table_association" "a" {
    vpc_id = "${aws_vpc.main.id}"
    route_table_id = "${aws_route_table.main_route.id}"
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.1.0.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "Integration Test Subnet"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "Integration Test Gateway"
    }
}

output "vpc_metadata" {
  value = {
        vpc_id = "${aws_vpc.main.id}"
        subnet_id = "${aws_subnet.main.id}"
  }
}

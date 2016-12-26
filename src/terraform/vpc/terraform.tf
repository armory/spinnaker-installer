resource "aws_vpc" "main" {
    cidr_block = "10.1.0.0/16"

    tags {
        Name = "Integration Test VPC"
    }
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.1.0.0/24"

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


module "provider" {
    source = "../modules/provider"
    aws_region = "${var.aws_region}"
}

module "sg" {
    source = "../modules/sg"
    vpc_id = "${var.vpc_id}"
    sg_name = "${armoryspinnaker_default_sg_name}"
}

variable "armoryspinnaker_default_security_group_id" {
    value = "${module.sg.id}"
}

module "external_elb" {
    source = "../modules/external-elb"
    elb_name = "${var.armoryspinnaker_external_elb_name}"
    vpc_id = "${var.vpc_id}"
    subnet_ids = "${var.armoryspinnaker_subnet_ids}"
    default_sg_id = "${armoryspinnaker_default_security_group_id}"
    external_sg_name = "${var.armoryspinnaker_external_sg_name}"
}

/*
module "managing-roles" {
    source = "../modules/managing-roles"
}
*/

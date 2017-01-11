
module "provider" {
    source = "../modules/provider"
}

module "sg" {
    source = "../modules/sg"
}

variable "armoryspinnaker_default_security_group_id" {
    value = "${module.sg.id}"
}

module "external_elb" {
    source = "../modules/external-elb"
}
/*
module "managing-roles" {
    source = "../modules/managing-roles"
}
*/

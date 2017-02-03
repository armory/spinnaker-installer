

module "external_elb" {
    source = "../modules/external-elb"
}

module "sg" {
    source = "../modules/sg"
}

module "managing-roles" {
    source = "../modules/managing-roles"
}

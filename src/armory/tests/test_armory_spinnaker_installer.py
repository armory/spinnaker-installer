from boto import ec2, vpc
import requests
from functools import partial
from armory import installer

import os

KEY_PAIR_NAME="packager-integration-keypair"
SECURITY_GROUPS=["default", "spinnaker_allow_armory-spinnaker"]
DEBUG=False
INSTANCE_TYPE="t2.micro"
SSH_USER_NAME="ubuntu"
DEFAULT_REGION="us-west-2"
CIDR_BLOCK="10.1.0.0/24"
SUBNET_CIDR="10.1.0.0/28"
VPC_NAME_TAG="Integration Test Temp VPC"


def create_armory_instance(conn, image_id, key_pair_name, reservation_fn):
    tf_vars= {
        'TF_VAR_vpc_id':'vpc-037ea264',
        'TF_VAR_armory_s3_bucket':'armory-spkr',
        'TF_VAR_armory_subnet_id':'subnet-0c14057a',
        'TF_VAR_availability_zones': 'us-west-2a',
        'TF_VAR_aws_region': 'us-west-2',
        'TF_VAR_key_name': key_pair_name
    }
    os.environ.update(tf_vars)

def create_resources(context):
    context['vpc'] = context['get_vpc']()
    context['subnet'] = context['get_subnet'](context['vpc'])
    print("creating gateway...")
    context['gateway'] = context['get_gateway'](context['vpc'],context['subnet'])
    print("getting key pair...")
    context['key_pair'] = context['get_key_pair']()

def clean_up_resources(context):
    try:
        context['delete_gateway'](context['vpc'], context['gateway'])
        context['delete_vpc'](context['vpc'])
        context['delete_key_pair']()
    except Exception as err:
        exc_info = sys.exc_info()
        traceback.print_exception(*exc_info)

def get_key_pair(conn, key_pair_name):
    try:
        print("finding existing key pairs if any")
        key = conn.get_all_key_pairs(keynames=[key_pair_name])[0]
        conn.delete_key_pair(key_pair_name, dry_run=DEBUG)
    except Exception as e:
        print("key pair: %s does not exist, creating new one" % key_pair_name)
        print(e)

    key_pair = conn.create_key_pair(key_pair_name, dry_run=DEBUG)
    print("returning key pair")
    return key_pair

def create_gateway(vpc_conn, vpc, subnet):
    # Create an Internet Gateway
    gateway = vpc_conn.create_internet_gateway()
    vpc_conn.attach_internet_gateway(gateway.id, vpc.id)
    #route_table = conn.create_route_table(vpc.id)
    # Associate Route Table with our subnet
    #conn.associate_route_table(route_table.id, subnet.id)

    # Create a Route from our Internet Gateway to the internet
    #route = conn.create_route(route_table.id, '0.0.0.0/0', gateway.id)
    return gateway

def delete_gateway(vpc_conn, vpc, gateway):
    vpc_conn.detach_internet_gateway(gateway.id, vpc.id, dry_run=False)
    vpc_conn.delete_internet_gateway(gateway.id)

def create_vpc(vpc_conn, vpc_name_tag, cidr_block, delete_vpc):
    print("creating/getting new VPC")
    vpcs = vpc_conn.get_all_vpcs(filters={'cidrBlock':cidr_block, 'tag-value':vpc_name_tag})
    for vpc in vpcs: delete_vpc(vpc)

    vpc = vpc_conn.create_vpc(cidr_block)
    print("created new vpc with id:%s" % vpc.id)
    vpc.add_tag("Name", vpc_name_tag)

    return vpc

def create_subnet(vpc_conn, vpc_name_tag, subnet_cidr, vpc):
    subnet = vpc_conn.create_subnet(vpc.id, cidr_block=subnet_cidr)
    subnet.add_tag("Name", vpc_name_tag)

def delete_vpc(vpc_conn, vpc):
    print("deleting subnets for:%s" % vpc.id)
    for subnet in vpc_conn.get_all_subnets(filters={'vpcId':vpc.id}): vpc_conn.delete_subnet(subnet.id)

    print("deleting vpc: %s" % vpc.id)
    vpc.delete()

def get_vpc(vpc_conn, vpc_name_tag, cidr_block, delete_vpc):
    vpcs = vpc_conn.get_all_vpcs(filters={'cidrBlock':cidr_block, 'tag-value':vpc_name_tag})
    return vpcs[0]

def get_subnet(vpc_conn, vpc_name_not_used, subnet_cidr_not_used, vpc):
    return vpc_conn.get_all_subnets(filters={'vpcId':vpc.id})[0]

def exec_tf(bash):

    pass

def test_armory_spinnaker_ami():

    install_version = os.environ.get("INSTALLER_VERSION", "")
    url = "http://get.armory.io/%s" % install_version
    vpc_conn = vpc.connect_to_region(DEFAULT_REGION)
    ec2_conn = ec2.connect_to_region(DEFAULT_REGION)
    context = {
        'vpc_conn':  vpc_conn,
        'ec2_conn': ec2_conn,
        'get_vpc': partial(create_vpc, vpc_conn, VPC_NAME_TAG, CIDR_BLOCK, partial(delete_vpc, vpc_conn)),
        #'get_vpc': partial(get_vpc, vpc_conn, VPC_NAME_TAG, CIDR_BLOCK, partial(delete_vpc, vpc_conn)),
        'get_subnet': partial(create_subnet, vpc_conn, VPC_NAME_TAG, SUBNET_CIDR),
        #'get_subnet': partial(get_subnet, vpc_conn, VPC_NAME_TAG, SUBNET_CIDR),
        'get_key_pair': partial(get_key_pair, ec2_conn, KEY_PAIR_NAME),
        'delete_key_pair': partial(ec2_conn.delete_key_pair, KEY_PAIR_NAME),
        'delete_vpc': partial(delete_vpc, vpc_conn),
        'get_gateway': partial(create_gateway, vpc_conn),
        'delete_gateway': partial(delete_gateway, vpc_conn)
    }
    try:
        #create_resources(context)
        installer.install_armory_spinnaker("vpc-31e64556", "subnet-f6130980", KEY_PAIR_NAME)
    finally:
        pass
        #clean_up_resources(context)

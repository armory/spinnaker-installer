
from boto import ec2, vpc
from functools import partial

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

    reservation = reservation_fn()
    instance = reservation.instances[0]
    boto.manage.cmdshell.sshclient_from_instance(
          instance,
          "/tmp/%s.pem" % key_pair_name,
          host_key_file=r'~/.ssh/known_hosts',
          user_name=SSH_USER_NAME,
       )

def create_resources(context):
    context['vpc'] = context['get_vpc']()
    print("getting key pair...")
    context['key_pair'] = context['get_key_pair']()

def clean_up_resources(context):
    context['delete_vpc'](context['vpc'])
    context['delete_key_pair']()

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

def get_vpc(vpc_conn, vpc_name_tag, cidr_block, subnet_cidr, delete_vpc):
    print("creating/getting new VPC")
    vpcs = vpc_conn.get_all_vpcs(filters={'cidrBlock':cidr_block, 'tag-value':vpc_name_tag})
    for vpc in vpcs: delete_vpc(vpc)

    vpc = vpc_conn.create_vpc(cidr_block)
    print("created new vpc with id:%s" % vpc.id)
    vpc.add_tag("Name", vpc_name_tag)

    subnet = vpc_conn.create_subnet(vpc.id, cidr_block=subnet_cidr)
    subnet.add_tag("Name", vpc_name_tag)
    return vpc

def delete_vpc(vpc_conn, vpc):
    print("deleting subnets for:%s" % vpc.id)
    for subnet in vpc_conn.get_all_subnets(filters={'vpcId':vpc.id}): vpc_conn.delete_subnet(subnet.id)

    print("deleting vpc: %s" % vpc.id)
    vpc.delete()

def test_armory_spinnaker_ami():
    vpc_conn = vpc.connect_to_region(DEFAULT_REGION)
    ec2_conn = ec2.connect_to_region(DEFAULT_REGION)
    context = {
        'vpc_conn':  vpc_conn,
        'ec2_conn': ec2_conn,
        'get_vpc': partial(get_vpc, vpc_conn, VPC_NAME_TAG, CIDR_BLOCK, SUBNET_CIDR, partial(delete_vpc, vpc_conn)),
        'get_key_pair': partial(get_key_pair, ec2_conn, KEY_PAIR_NAME),
        'delete_key_pair': partial(ec2_conn.delete_key_pair, KEY_PAIR_NAME),
        'delete_vpc': partial(delete_vpc, vpc_conn)
    }
    try:
        create_resources(context)
    except Exception as e:
        print("Error happened, more details below")
        print(e)
    finally:
        clean_up_resources(context)
    #create_resources(context)
    # image_id = os.environ["IMAGE_ID"]
    # conn = ec2.connect_to_region("us-west-2")
    # instance = create_armory_instance(conn, \
    #     image_id, \
    #     KEY_PAIR_NAME, \
    #     partial(find_reservation, conn)
    # )
    # clean_up_resources(KEY_PAIR_NAME)
# Find the instance object related to my instanceId
#
# # Create an SSH client for our instance
# #    key_path is the path to the SSH private key associated with instance
# #    user_name is the user to login as on the instance (e.g. ubuntu, ec2-user, etc.)
# ssh_client = sshclient_from_instance(instance,
#                                      '<path to SSH keyfile>',
#                                      user_name='ec2-user')
# # Run the command. Returns a tuple consisting of:
# #    The integer status of the command
# #    A string containing the output of the command
# #    A string containing the stderr output of the command
# status, stdout, stderr = ssh_client.run('ls -al')
    print("testing")

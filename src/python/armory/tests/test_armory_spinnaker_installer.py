from boto import ec2, vpc
import requests
from functools import partial
from armory import installer, crypto
from os import chmod, path, environ, O_WRONLY
import time
import sys
import json
import os
from boto.manage.cmdshell import sshclient_from_instance
import paramiko
from armory import cmd
import unittest
from armory import http
import random

def env_or_default(key, default_value):
    val = environ.get(key, default_value)
    if val: #this returns false for empty strings
        return val
    else:
        return default_value

TEST_TIMEOUT = int(env_or_default("SPINNAKER_TEST_TIMEOUT", 900))
BACKOFF_MAX = 10
BACKOFF_FACTOR = 1
NUM_RETRIES = int(TEST_TIMEOUT/BACKOFF_MAX)
PRIVATE_KEY_PATH = "%s/private.key" % path.dirname(path.realpath(__file__))
PUBLIC_KEY_PATH = "%s/public.key" % path.dirname(path.realpath(__file__))

import waiting

def wait_for(fn):
    waiting_desc = "Waiting for %s to complete" % str(fn)
    return waiting.wait(fn,
                        timeout_seconds=TEST_TIMEOUT,
                        sleep_seconds=(BACKOFF_FACTOR, BACKOFF_MAX),
                        on_poll=lambda: print(waiting_desc)
                    )

class TestSpinnakerInstaller(unittest.TestCase):

    elb_hostname = None
    ssh_client = None
    http_session = None
    vpc_id = None
    subnet_id = None
    test_runid = None

    @classmethod
    def setUpClass(cls):
        cls.test_runid = env_or_default("SPINNAKER_TEST_RUNID", "%05d" % random.randint(0,99999))
        try:
            cls.setUpInfrastructure()
        except Exception as e:
            print("exception raised, tearing down infrastructure: %s" % e)
            cls.tearDownClass()
            #re-raise exception so that tests don't continue
            raise e

    @classmethod
    def tearDownClass(cls):
        def str2bool(v):
            return v.lower() in ("yes", "true", "t", "1")
        should_tear_down = str2bool(env_or_default("SPINNAKER_TEARDOWN", "True"))
        if should_tear_down:
            try:
                installer.destroy_armory_spinnaker(cls.test_runid, cls.vpc_id, cls.subnet_id)
            except Exception as e:
                print("destroying armory spinnaker failed: %s" % e)
            try:
                installer.destroy_vpc(cls.test_runid, cls.public_key)
            except Exception as e:
                print("destroying vpc failed: %s" % e)
        else:
            print("not tearing down infrastructure due to SPINNAKER_TEARDOWN=%s" % should_tear_down)

    @classmethod
    def setUpInfrastructure(cls):
        print("creating session with timeout: %s and back off max: %s" % (TEST_TIMEOUT, BACKOFF_MAX))
        cls.http_session = http.create_session(NUM_RETRIES, BACKOFF_FACTOR, BACKOFF_MAX)
        cls.elb_hostname = env_or_default("SPINNAKER_ELB_HOSTNAME", None)
        cls.vpc_id = env_or_default("TF_VAR_vpc_id", None)
        cls.subnet_id = env_or_default("TF_VAR_subnet_id", None)
        instance_ip = env_or_default("SPINNAKER_INSTANCE_IP", None)

        new_private_key = False
        if path.exists(PUBLIC_KEY_PATH) and path.exists(PRIVATE_KEY_PATH):
            print("using existing public key path: %s" % PRIVATE_KEY_PATH)
            cls.public_key = open(PUBLIC_KEY_PATH).read()
        else:
            new_private_key = True
            print("creating new private key for keypair %s" % PRIVATE_KEY_PATH)
            private_pem, cls.public_key = crypto.generate_keypair()
            with open(PRIVATE_KEY_PATH,'w', 0o600) as f: f.write(private_pem)
            with open(PUBLIC_KEY_PATH, 'w', 0o600) as f: f.write(cls.public_key)

        if not cls.vpc_id or new_private_key:
            cls.vpc_id, cls.subnet_id = installer.create_vpc(cls.test_runid, cls.public_key)
        else:
            print("not creating vpc, using existing: %s" % cls.vpc_id)

        if not cls.elb_hostname:
            print("using spinnaker installer")
            result = installer.install_armory_spinnaker(cls.test_runid, cls.vpc_id, cls.subnet_id)
            cls.elb_hostname = result['spinnaker_url']
        else:
            print("not creating new spinnaker instance, using existing elb: %s" % cls.elb_hostname)

        if not instance_ip:
            print("no instance ip was given, finding one")
            conn = ec2.connect_to_region(installer.AWS_REGION)
            find_instance = partial(installer.find_spinnaker_instance,
                                conn,
                                cls.vpc_id,
                                cls.subnet_id,
                            )
            instance = wait_for(find_instance)
            instance_ip = instance.ip_address
            print("no instance ip passed in, found this one: %s" % instance_ip)
        else:
            print("using instance ip passed in through env vars: %s" % instance_ip)

        print("trying to connect to %s" % instance_ip)

        get_ssh_client = partial(
                    cmd.ssh_client,
                    instance.ip_address,
                    "ubuntu",
                    PRIVATE_KEY_PATH,
                )

        cls.ssh_client = wait_for(get_ssh_client)

    def test_endpoint_access(self):
        response = self.http_session.get("http://%s/" % self.elb_hostname, timeout=1)
        self.assertEquals(response.status_code, 200)

    def test_gate_access(self):
        response = self.http_session.get("http://%s:8084/credentials" % self.elb_hostname, timeout=1)
        self.assertEquals(response.status_code, 200)

        credentials = json.loads(response.text)
        self.assertEquals(len(credentials), 1)
        self.assertEquals("default", credentials[0]["name"])

    def test_access_to_s3(self):
        status, stdout, stderr = cmd.ssh_command(self.ssh_client, 'aws s3 ls %s' % installer.S3_BUCKET)
        self.assertEquals(status, 0, stdout)

    def test_access_to_ecr(self):
        status, stdout, stderr = cmd.ssh_command(self.ssh_client, 'aws ecr get-login --region %s --registry-ids 515116089304' % installer.AWS_REGION)
        self.assertEquals(status, 0, stdout)

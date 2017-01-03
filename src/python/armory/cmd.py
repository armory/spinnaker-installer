import requests
import subprocess
import sys
import paramiko
import time


def exec_cmd(cmd):
    print("Executing: %s" % cmd)

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output = ""
    while True:
        line = process.stdout.readline()
        sys.stdout.write(line.decode('utf-8'))
        output += line.decode('utf-8')
        sys.stdout.flush()
        if not line: break

    while True:
        line_err = process.stderr.readline()
        sys.stdout.write(line_err.decode('utf-8'))
        if not line_err: break

    print("process return code is: %s" % process.wait())
    return (process.returncode, output)

def ssh_client(ip_address, username, private_key_path):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print("creating connection for %s" % ip_address)
    try:
        ssh.connect(ip_address, username=username, key_filename=private_key_path)
    except Exception as e:
        ssh = None
        print("except connecting to: %s" % ip_address)
        print("exception: %s" % e)

    return ssh

def ssh_command(ssh_client, command):
    print('running:%s' % command)
    stdin_file, stdout_file, stderr_file = ssh_client.exec_command(command)

    stdout = stdout_file.read()
    status  = stdout_file.channel.recv_exit_status()
    stderr = stderr_file.read()

    stdin_file.close()
    stdout_file.close()
    stderr_file.close()

    print('stdout: %s' % stdout)
    print('stderr: %s' % stderr)
    return (status, stdout, stderr)

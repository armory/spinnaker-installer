import requests
import subprocess
import sys

def exec_cmd(cmd):
    print("Executing: %s" % cmd)

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output = ""
    while True:
        line = process.stdout.readline()
        sys.stdout.write(line.decode('utf-8'))
        output += line.decode('utf-8')
        #print out err
        line_err = process.stderr.readline()
        sys.stdout.write(line_err.decode('utf-8'))
        if not line and not line_err: break
    #TODO: this should return the correct return result from the last command run
    print("process return code is: %s" % process.wait())
    return (process.returncode, output)

#!/usr/bin/env python

import os
from lxml import etree
import datetime
import json
from fabric.operations import local
from fabric.api import settings
import shutil
import commands
from copy import deepcopy
from dealer.git import git
import sys
import re
from time import sleep

out_dir = 'acceptance_results'

def get_du(path):
    """get disk usage for a given path"""
    cmd = 'df %s | grep -v "^File" | head -1 | awk \'{print $3}\'' % path
    res = int(commands.getoutput(cmd).strip())
    return res

def get_interfaces():
    ifaces = {}
    cmd = 'nmcli -t -f DEVICE,TYPE,STATE d'
    res = commands.getoutput(cmd).strip()
    if 'nmcli-CRITICAL' in res:
        return {}
    lines = res.split("\n")
    for line in lines:
        name, dev_type, state = line.split(':')
        ifaces[name] = {'type': dev_type, 'state': state}
    return ifaces

def parse_junit(fname):
    xml = etree.parse(fname)
    root = xml.getroot()
    suite = root.xpath('/testsuite')[0]
    result = deepcopy(dict(suite.attrib))
    result['tests'] = []
    for test in root.xpath('/testsuite/testcase'):
        t = deepcopy(dict(test.attrib))
        t['success'] = True
        t['fail_message'] = ''
        failures = test.xpath('failure')
        if len(failures) > 0:
            t['success'] = False
            t['fail_message'] = failures[0].attrib['message']
        result['tests'].append(t)
    return result

def get_vboxinfo():
    # this largely uses code from Vagrant -
    # plugins/providers/virtualbox/driver/version_4_3.rb
    res = {}
    try:
        res['hostonlyifs'] = get_vbox_hostonlyifs()
    except:
        print("ERROR: unable to get VirtualBox hostonlyifs")
    try:
        res['dhcpservers'] = get_vbox_dhcpservers()
    except:
        print("ERROR: unable to get VirtualBox dhcpservers")
    return res

def get_vbox_hostonlyifs():
    ifnum = 0
    out = commands.getoutput('VBoxManage list hostonlyifs')
    ifs = out.split("\n\n")
    result = {}
    for iface in ifs:
        lines = iface.split("\n")
        data = {}
        for line in lines:
            line = line.strip()
            if line == '':
                continue
            parts = line.split(' ', 1)
            data[parts[0].strip().strip(':')] = parts[1].strip()
        key = 'unknown_{n}'.format(n=ifnum)
        ifnum += 1
        for x in ['Name', 'VBoxNetworkName', 'GUID']:
            if x in data:
                key = data[x]
                break
        result[key] = data
    return result

def get_vbox_dhcpservers():
    ifnum = 0
    out = commands.getoutput('VBoxManage list dhcpservers')
    ifs = out.split("\n\n")
    result = {}
    for iface in ifs:
        lines = iface.split("\n")
        data = {}
        for line in lines:
            line = line.strip()
            if line == '':
                continue
            parts = line.split(' ', 1)
            data[parts[0].strip().strip(':')] = parts[1].strip()
        key = 'unknown_{n}'.format(n=ifnum)
        ifnum += 1
        if 'NetworkName' in data:
            key = data['NetworkName']
        result[key] = data
    return result

def do_test(num, testcmd):
    data = {'num': num}
    data['git_rev'] = git.revision
    data['git_tag'] = git.tag

    # output path and command to execute
    outfile = '{o}/do_test_{n}.out'.format(n=num, o=out_dir)
    data['outfile'] = outfile
    cmd = testcmd + ' 2>&1 | tee ' + outfile + ' ; ( exit ${PIPESTATUS[0]} )'

    print("################ BEGIN test {n} ###############################".format(n=num))
    start_dt = datetime.datetime.now()
    
    # run the command, send stdout/stderr to console, capture exit code; do not die on non-0 exit
    with settings(warn_only=True):
        result = local(cmd, capture=False, shell='/bin/bash')
    print("################ END test {n} ###############################".format(n=num))

    # calculate duration
    end_dt = datetime.datetime.now()
    duration = (end_dt - start_dt).total_seconds()
    print("Command exited {x} in {d} seconds".format(x=result.return_code, d=duration))

    # update data
    data['success'] = result.succeeded
    data['return_code'] = result.return_code
    data['duration'] = duration

    # system state
    du = get_du('/tmp/vagrant-r10k-spec')
    data['tmp_disk_used_KB'] = du
    data['interfaces'] = get_interfaces()

    # VBox info
    data['vboxinfo'] = get_vboxinfo()
    
    # JUnit
    if os.path.exists('results.xml'):
        fpath = '{o}/results_{n}.xml'.format(n=num, o=out_dir)
        shutil.move('results.xml', fpath)
        data['junit'] = parse_junit(fpath)
        data['junit_path'] = fpath

    json_path = '{o}/data_{n}.json'.format(n=num, o=out_dir)
    with open(json_path, 'w') as fh:
        fh.write(json.dumps(data))
    print("\tData written to: {j}".format(j=json_path))

def get_next_test_num(dirname):
    file_re = re.compile('^data_(\d+)\.json$')
    num = 0
    for f in os.listdir(dirname):
        m = file_re.match(f)
        if not m:
            continue
        n = int(m.group(1))
        if n > num:
            num = n
    return (num + 1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.stderr.write("USAGE: testrunner.py <# to run>\n")
        raise SystemExit(1)
    
    num_to_run = int(sys.argv[1])
    
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    start_num = get_next_test_num(out_dir)

    print("About to run {n} tests...".format(n=num_to_run))
    for i in range(start_num, (start_num + num_to_run)):
        print(">>>> Doing test {i}".format(i=i))
        do_test(i, 'bundle exec rake --trace acceptance:virtualbox')
        print(">>> Sleeping 30s between test runs")
        sleep(30)

#!/usr/bin/env python

import json
import os
import re
import sys
from testrunner import out_dir

test_base_name = 'provider/virtualbox/vagrant-r10k it should behave like provider/vagrant-r10k '
test_names = {
    'configured correctly deploys Puppetfile modules':                 'correct_deploy_modules',
    'configured correctly hooks in the right order':                   'correct_hook_order    ',
    'puppet directory missing errors during config validation':        'config_validation_err ',
    'module path different from Puppet provisioner skips r10k deploy': 'mod_path_different    ',
    'Puppetfile syntax error fails during module deploy':              'syntax_error_fails    ',
}

xmltmp_re = re.compile(r"VBoxManage: error: Runtime error opening '[^']+' for reading: -102\(File not found\.\)")

def find_error(output):
    if xmltmp_re.search(output):
        return "xml.tmp_-102" # Runtime error opening '<tmp path>/home/.config/VirtualBox/VirtualBox.xml-tmp' for reading: -102(File not found.).
    elif 'VERR_DISK_FULL' in output:
        return 'VERR_DISK_FULL'
    print(output)
    raise SystemExit()
    return "unknown"

def analyze_run(d):
    sys.stdout.write("{n},".format(n=d['num']))
    sys.stdout.write("{n},".format(n=d['success']))
    sys.stdout.write("{n},".format(n=d['return_code']))
    #sys.stdout.write("{n},".format(n=d['duration']))
    sys.stdout.write("{n},".format(n=len(d['interfaces'])))
    sys.stdout.write("{n},".format(n=len(d['vboxinfo']['hostonlyifs'])))
    sys.stdout.write("{n},".format(n=len(d['vboxinfo']['dhcpservers'])))
    sys.stdout.write("{n},".format(n=d['junit']['failures'])) # count
    sys.stdout.write("{n},".format(n=d['junit']['errors'])) # count
    for test in d['junit']['tests']:
        name = test['name'].replace(test_base_name, '')
        if name in test_names:
            name = test_names[name]
        if test['success']:
            sys.stdout.write("{n} <pass>,".format(n=name))
        else:
            err = find_error(test['fail_message'])
            sys.stdout.write("{n} <FAIL:{e}>,".format(n=name, e=err))
    sys.stdout.write("\n")

def do_analysis(dirname):
    results = {}
    json_re = re.compile('^data_\d+\.json$')
    for f in os.listdir(dirname):
        if not json_re.match(f):
            continue
        with open(os.path.join(dirname, f), 'r') as fh:
            raw = fh.read()
        tmp = json.loads(raw)
        results[tmp['num']] = tmp
    # tmp is now our full data for all tests
    for num in sorted(results):
        analyze_run(results[num])

if __name__ == "__main__":
    sys.stdout.write("{n},".format(n='TestNum'))
    sys.stdout.write("{n},".format(n='Success'))
    sys.stdout.write("{n},".format(n='RetCode'))
    #sys.stdout.write("{n},".format(n='Duration'))
    sys.stdout.write("{n},".format(n='Num_IFaces'))
    sys.stdout.write("{n},".format(n='Num_VB_HostIfs'))
    sys.stdout.write("{n},".format(n='Num_VB_DHCPs'))
    sys.stdout.write("{n},".format(n='Num_Failures'))
    sys.stdout.write("{n},".format(n='Num_Errors'))
    sys.stdout.write("Test1,Test2,Test3,Test4,Test5")
    sys.stdout.write("\n")
    do_analysis(out_dir)

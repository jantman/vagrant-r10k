#!/usr/bin/env python

import json
import os
import re
import sys
from testrunner import out_dir
from collections import defaultdict

test_base_name = 'provider/virtualbox/vagrant-r10k it should behave like provider/vagrant-r10k '
test_names = {
    'configured correctly deploys Puppetfile modules':                 'correct_deploy_modules',
    'configured correctly hooks in the right order':                   'correct_hook_order    ',
    'puppet directory missing errors during config validation':        'config_validation_err ',
    'module path different from Puppet provisioner skips r10k deploy': 'mod_path_different    ',
    'Puppetfile syntax error fails during module deploy':              'syntax_error_fails    ',
}

xmltmp_re = re.compile(r"VBoxManage: error: Runtime error opening '[^']+' for reading: -102\(File not found\.\)")

test_results = defaultdict(list)

def find_error(output):
    if xmltmp_re.search(output):
        return "xml.tmp_-102" # Runtime error opening '<tmp path>/home/.config/VirtualBox/VirtualBox.xml-tmp' for reading: -102(File not found.).
    elif 'VERR_DISK_FULL' in output:
        return 'VERR_DISK_FULL'
    print(output)
    raise SystemExit()
    return "unknown"

def analyze_run(d):
    s = ''
    s += "{n},".format(n=d['num'])
    s += "{n},".format(n=d['success'])
    s += "{n},".format(n=d['return_code'])
    s += "{n},".format(n=d['duration'])
    s += "{n},".format(n=d['mtime'])
    s += "{n},".format(n=len(d['interfaces']))
    s += "{n},".format(n=len(d['vboxinfo']['hostonlyifs']))
    s += "{n},".format(n=len(d['vboxinfo']['dhcpservers']))
    s += "{n},".format(n=d['junit']['failures'])
    s += "{n},".format(n=d['junit']['errors'])
    for test in d['junit']['tests']:
        name = test['name'].replace(test_base_name, '')
        if name in test_names:
            name = test_names[name]
        if test['success']:
            s += "{n} <pass>,".format(n=name)
            test_results[name].append('P')
        else:
            err = find_error(test['fail_message'])
            s += "{n} <FAIL:{e}>,".format(n=name, e=err)
            test_results[name].append('F')
    s += "\n"
    return s

def do_analysis(dirname):
    results = {}
    json_re = re.compile('^data_\d+\.json$')
    for f in os.listdir(dirname):
        if not json_re.match(f):
            continue
        fpath = os.path.join(dirname, f)
        with open(fpath, 'r') as fh:
            raw = fh.read()
        tmp = json.loads(raw)
        tmp['mtime'] = os.path.getmtime(fpath)
        results[tmp['num']] = tmp
    # tmp is now our full data for all tests
    s = ''
    for num in sorted(results):
        s += analyze_run(results[num])
    return s

if __name__ == "__main__":
    s = ''
    s += "{n},".format(n='TestNum')
    s += "{n},".format(n='Success')
    s += "{n},".format(n='RetCode')
    s += "{n},".format(n='Duration')
    s += "{n},".format(n='EndTime')
    s += "{n},".format(n='Num_IFaces')
    s += "{n},".format(n='Num_VB_HostIfs')
    s += "{n},".format(n='Num_VB_DHCPs')
    s += "{n},".format(n='Num_Failures')
    s += "{n},".format(n='Num_Errors')
    s += "Test1,Test2,Test3,Test4,Test5"
    s += "\n"
    s += do_analysis(out_dir)
    print(s)
    with open('analysis_details.csv', 'w') as fh:
        fh.write(s)
    sys.stderr.write("\n\nDetailed analysis written to analysis_details.csv\n\n")

    s = ''
    for testname in test_results:
        s += "{t},".format(t=testname)
        s += ','.join(test_results[testname])
        s += "\n"
    print(s)
    with open('analysis_tests.csv', 'w') as fh:
        fh.write(s)
    sys.stderr.write("\n\nPer-test analysis written to analysis_tests.csv\n\n")

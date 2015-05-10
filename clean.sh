#!/bin/bash

for i in $(VBoxManage list dhcpservers | grep "^NetworkName:" | awk '{print $2}'); do echo $i; VBoxManage dhcpserver remove --netname $i; done
for i in $(VBoxManage list hostonlyifs | grep "^Name:" | awk '{print $2}'); do echo $i; VBoxManage hostonlyif remove $i; done

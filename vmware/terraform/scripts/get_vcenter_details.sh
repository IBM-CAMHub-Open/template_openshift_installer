#!/bin/bash

vcenter=`echo $VSPHERE_SERVER`
vcenteruser=`echo $VSPHERE_USER`
vcenterpassword=`echo $VSPHERE_PASSWORD`
jq -n --arg vcenter "$vcenter" --arg vcenteruser "$vcenteruser" --arg vcenterpassword "$vcenterpassword" '{"vcenter":$vcenter,"vcenteruser":$vcenteruser,"vcenterpassword":$vcenterpassword}'

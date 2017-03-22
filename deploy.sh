#!/bin/bash

# Per-VM configuration
NAME=kube-worker01
CPUS=2
MEMORY=2048 # MB
IP=192.168.64.220/24
HD=32 # GB, must be >9 for now
VMNETWORK="VM Network"
GATEWAY=192.168.64.1
DNS=192.168.64.5
DOMAIN=lab.mattwilson.org

# ESXi Host Configuration
ESXIHOST=vm710.lab.mattwilson.org
ESXIUSER=mwilson
VMDATASTORE=/vmfs/volumes/datastore1
COREOS_IMAGE=$VMDATASTORE/_templates/coreos/coreos_production_vmware_image.vmdk

## Shouldn't need to change below here

B64_CMD="base64 -w0"
[ $(uname -s) = "Darwin" ] &&
    B64_CMD="base64"

# Substitute placeholders in Ignition template and generate base64 string
IGNITION=$(sed "s-{IP}-$IP-g" ignition-template.json | \
    sed "s/{GATEWAY}/$GATEWAY/g" | \
    sed "s/{DNS}/$DNS/g" | \
    sed "s/{DOMAIN}/$DOMAIN/g" | \
    sed "s/{NAME}/$NAME/g" | \
    $B64_CMD)

# Substitute values in VMX template and write to disk
sed "s/{RAM}/$MEMORY/g" vmx-template.txt | \
    sed "s/{CPU}/$CPUS/g" | \
    sed "s/{NAME}/$NAME/g" | \
    sed "s/{VMNETWORK}/$VMNETWORK/g" | \
    sed "s/{IGNITION}/$IGNITION/g" \
    >$NAME.vmx

# Now do it
# TODO: really need to check that the VM doesn't already exist,
#       check for errors, etc. This is just rough proof-of-concept

# you're really going to want your SSH agent to load your key so you don't
# have to keep typing in your password...

ssh $ESXIUSER@$ESXIHOST mkdir "$VMDATASTORE/$NAME"
scp $NAME.vmx "$ESXIUSER@$ESXIHOST:/$VMDATASTORE/$NAME"
ssh $ESXIUSER@$ESXIHOST vmkfstools -i "$COREOS_IMAGE" -d thin "$VMDATASTORE/$NAME/$NAME.vmdk"
ssh $ESXIUSER@$ESXIHOST vmkfstools -X ${HD}G "$VMDATASTORE/$NAME/$NAME.vmdk"
ssh $ESXIUSER@$ESXIHOST vim-cmd solo/registervm "$VMDATASTORE/$NAME/$NAME.vmx"

# Cleanup
rm "$NAME.vmx"


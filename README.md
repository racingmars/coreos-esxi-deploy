# CoreOS on VMWare ESXi

VMWare is a community-supported platform for CoreOS, but the OVA deployment
method has not worked well for me. Among other reasons, a big one is that the
free version of ESXi, without vSphere/vCenter, does not persist the guest info.
Additionally, even when I got that sorted out, the cloud-init/cloud-config
method that sets static IPs based on the guestinfo wasn't working well for me
and had problems such as not releasing the DHCP address it got before the
systemd network unit was create.

In any case, it just wasn't working at all for me. What did work was using the
VMDK image that CoreOS publishes, and using Ignition to set the IP information.
By creating the VMX file manually and registering it with ESXi, the Ignition
info can be passed in through guestinfo and everything appears to work as
expected.

## Caveats

This is basically just a rough prototype. No error checking, won't work (and
might do damage) if the requested VM name already exists. Would be nice to have
more flexibility with different Ignition templates. Etc. etc. etc. Use at your
own risk.

I'm using VMWare ESXi 6.5, and the VMX template I created is for the
latest-and-greatest config and virtual hardware versions. If you have a VMWare
version older than 6.5, this may not work.

## Instructions

First, the CoreOS VMDK needs to exist on your ESXi server. [Download the
current stable version](https://stable.release.core-os.net/amd64-usr/current/coreos_production_vmware_image.vmdk.bz2)
and place an uncompressed copy in your ESXi datastore.

Edit the `deploy.sh` file. Set the appropriate values under the "Per-VM
configuration" section and the "ESXi Host Configuration" section. The
`VMDATASTORE` variable is where the directory for the new VM will be created.
Point `COREOS_IMAGE` to wherever that VMDK you downloaded lives.

Once you've set all of the variable to your satisfaction, run `deploy.sh`. You
probably want to have SSH key authentication set up to your ESXi server, and
load your key into your agent. Otherwise you're going to have to type your
password five times in a row.

As long as I don't make any mistakes, this seems to work for me. This will
probably blow up your ESXi server and leave a crater in the floor of your
datacenter. Don't say I didn't warn you.



#!/bin/bash
set -eux

# firstboot isn't split out by role yet so we handle it this way
if ! hostname | grep compute &>/dev/null; then
 echo "Exiting. This script is only for the compute role."
 exit 0
fi

/sbin/setenforce 0
/sbin/modprobe ebtables

/usr/bin/systemctl stop docker.service
/bin/curl -o /tmp/docker https://get.docker.com/builds/Linux/x86_64/docker-$docker_version
/bin/mount -o remount,rw /usr
/bin/rm /bin/docker
/bin/cp /tmp/docker /bin/docker
/bin/chmod 755 /bin/docker

/usr/bin/systemctl enable docker.service
/usr/bin/systemctl restart --no-block docker.service

/usr/bin/systemctl disable NetworkManager
/usr/bin/systemctl stop NetworkManager

# Atomic's root partition & logical volume defaults to 3G.  In order to launch
# larger VMs, we need to enlarge the root logical volume and scale down the
# docker_pool logical volume. We are allocating 80% of the disk space for
# vm data and the remaining 20% for docker images.
ATOMIC_ROOT='/dev/mapper/atomicos-root'
ROOT_DEVICE=`pvs -o vg_name,pv_name --no-headings | grep atomicos | awk '{ print $2}'`

growpart $( echo "${ROOT_DEVICE}" | sed -r 's/([^0-9]*)([0-9]+)/\1 \2/' )
pvresize "${ROOT_DEVICE}"
lvresize -l +80%FREE "${ATOMIC_ROOT}"
xfs_growfs "${ATOMIC_ROOT}"

cat <<EOF > /etc/sysconfig/docker-storage-setup
GROWPART=true
AUTO_EXTEND_POOL=yes
POOL_AUTOEXTEND_PERCENT=30
POOL_AUTOEXTEND_THRESHOLD=70
EOF

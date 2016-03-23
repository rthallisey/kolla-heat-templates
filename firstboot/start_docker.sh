#!/bin/bash
set -eux

/sbin/setenforce 0
/sbin/modprobe ebtables

cat | sudo tee /etc/yum.repos.d/docker.repo << EOF
[docker]
name=Docker Main Repository
baseurl=https://yum.dockerproject.org/repo/main/fedora/23/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

sudo dnf install -y libffi-devel openssl-devel docker-engine btrfs-progs python-docker-py

sudo sed -i -r 's,(ExecStart)=(.+),\1=/usr/bin/docker daemon --insecure-registry=$docker_registry,' /usr/lib/systemd/system/docker.service
sudo sed -i 's|^MountFlags=.*|MountFlags=shared|' /usr/lib/systemd/system/docker.service
sudo systemctl daemon-reload

sudo systemctl start docker
sudo docker info

# Hostname needs to resolve
cat <<EOF >> /etc/hosts
172.0.0.1   `hostname | cut -f 1 -d '.'` localhost.localdomain
EOF

# The Fedora setup doesn't allow root login which is what it seems ansible
# wants so I'm going to copy the ssh key from the fedora user to /root.

cp -rv /home/fedora/.ssh /root/

# For verifying the node has booted and is ready.. not yet usable.
# os-collect-config
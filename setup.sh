#!/bin/bash

sudo yum install -y python-devel libffi-devel openssl-devel gcc git ansible

git clone https://git.openstack.org/openstack/kolla

pip install kolla/
(cd kolla && sudo cp -rv etc/kolla /etc/)

MYIP=`ifconfig eth0 | grep inet -m 1 | cut -f 10 -d ' '`

curl -fsSL https://get.docker.com/ | sh
echo "other_args='--insecure-registry ${MYIP}:4000'" | sudo tee -a /etc/sysconfig/docker

# Create the drop-in unit directory for docker.service
sudo mkdir -p /etc/systemd/system/docker.service.d

# Create the drop-in unit file
sudo tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
EnvironmentFile=/etc/sysconfig/docker
ExecStart=/usr/bin/docker daemon -H fd:// $other_args
EOF

# Run these commands to reload the daemon
systemctl daemon-reload
systemctl restart docker

tee ~/.ssh/config <<-'EOF'
Host 192.*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF

chmod 600 ~/.ssh/config

sudo systemctl start docker

sed -i s/x.x.x.x/$MY_IP/ kolla-heat-templates/environments/kolla.yaml

sudo docker run -d -p 4000:5000 --restart=always --name registry registry:2

(cd kolla && sudo ./tools/build.py keystone cron kolla-toolbox heka nova glance mariadb haproxy keepalived memcached neutron openvswitch heat horizon rabbitmq --base centos --tag latest --namespace kolla-tripleo -t binary --registry ${MYIP}:4000 --push)

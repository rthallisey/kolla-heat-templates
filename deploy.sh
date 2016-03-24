#!/bin/bash

openstack overcloud deploy --templates=kolla-heat-templates -e kolla-heat-templates/environments/kolla.yaml

heat output-show overcloud ip_addresses
heat output-show overcloud ip_addresses > overcloud_ip_list.txt

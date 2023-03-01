#!/bin/bash
#
# Copyright 2022 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
set -ex

if [ -z "${DEPLOY_DIR}" ]; then
    echo "Please set DEPLOY_DIR"; exit 1
fi

if [ ! -d ${DEPLOY_DIR} ]; then
    mkdir -p ${DEPLOY_DIR}
fi

if [ -z "${OVN_METADATA_AGENT_TRANSPORT_URL_USER}" ]; then
    echo "Please set OVN_METADATA_AGENT_TRANSPORT_URL_USER"; exit 1
fi

if [ -z "${OVN_METADATA_AGENT_TRANSPORT_URL_PASSWORD}" ]; then
    echo "Please set OVN_METADATA_AGENT_TRANSPORT_URL_PASSWORD"; exit 1
fi

if [ -z "${OVN_METADATA_AGENT_SB_CONNECTION}" ]; then
    echo "Please set OVN_METADATA_AGENT_SB_CONNECTION"; exit 1
fi

if [ -z "${EDPM_OVN_DBS}" ]; then
    echo "Please set EDPM_OVN_DBS"; exit 1
fi

if [ -z "${OVN_METADATA_AGENT_NOVA_METADATA_HOST}" ]; then
    echo "Please set OVN_METADATA_AGENT_NOVA_METADATA_HOST"; exit 1
fi

if [ -z "${OVN_METADATA_AGENT_PROXY_SHARED_SECRET}" ]; then
    echo "Please set OVN_METADATA_AGENT_PROXY_SHARED_SECRET"; exit 1
fi

if [ -z "${OVN_METADATA_AGENT_BIND_HOST}" ]; then
    echo "Please set OVN_METADATA_AGENT_BIND_HOST"; exit 1
fi

if [ -z "${CHRONY_NTP_SERVER}" ]; then
    echo "Please set CHRONY_NTP_SERVER"; exit 1
fi

echo DEPLOY_DIR ${DEPLOY_DIR}
echo OVN_METADATA_AGENT_TRANSPORT_URL_USER ${OVN_METADATA_AGENT_TRANSPORT_URL_USER}
echo OVN_METADATA_AGENT_TRANSPORT_URL_PASSWORD ${OVN_METADATA_AGENT_TRANSPORT_URL_PASSWORD}
echo OVN_METADATA_AGENT_SB_CONNECTION ${OVN_METADATA_AGENT_SB_CONNECTION}
echo EDPM_OVN_DBS ${EDPM_OVN_DBS}
echo OVN_METADATA_AGENT_NOVA_METADATA_HOST ${OVN_METADATA_AGENT_NOVA_METADATA_HOST}
echo OVN_METADATA_AGENT_PROXY_SHARED_SECRET ${OVN_METADATA_AGENT_PROXY_SHARED_SECRET}
echo OVN_METADATA_AGENT_BIND_HOST ${OVN_METADATA_AGENT_BIND_HOST}
echo CHRONY_NTP_SERVER ${CHRONY_NTP_SERVER}

cat > ${DEPLOY_DIR}/edpm-compute-role.yaml <<EOF_CAT
apiVersion: dataplane.openstack.org/v1beta1
kind: OpenStackDataPlaneRole
metadata:
  name: edpm-compute
spec:
EOF_CAT


cat > ${DEPLOY_DIR}/edpm-compute-0.yaml <<EOF_CAT
apiVersion: dataplane.openstack.org/v1beta1
kind: OpenStackDataPlaneNode
metadata:
  name: edpm-compute-0
  namespace: openstack
  labels:
    component: openstackdataplanenode
spec:
  role: edpm-compute
  hostName: edpm-compute-0
  ansibleHost: 192.168.122.100
  networkAttachments:
  - ctlplane
  node:
    networks:
      - network: ctlplane
        fixedIP: 192.168.122.100
      - network: internalapi
        fixedIP: 172.17.0.100
      - network: storage
        fixedIP: 172.18.0.100
      - network: tenant
        fixedIP: 172.10.0.100
    ansibleUser: root
    ansiblePort: 22
    ansibleSSHPrivateKeySecret: dataplane-ansible-ssh-private-key-secret
    deploy: true
    ansibleVars: |
      edpm_network_config_template: templates/single_nic_vlans/single_nic_vlans.j2
      edpm_network_config_hide_sensitive_logs: false
      edpm_ovn_dbs:
      - ${EDPM_OVN_DBS}
      edpm_hosts_entries_extra_hosts_entries:
      - 172.17.0.80 glance-internal.openstack.svc neutron-internal.openstack.svc cinder-internal.openstack.svc nova-internal.openstack.svc placement-internal.openstack.svc keystone-internal.openstack.svc
      - 172.17.0.85 rabbitmq.openstack.svc
      - 172.17.0.86 rabbitmq-cell1.openstack.svc
      edpm_ovn_metadata_agent_DEFAULT_transport_url: 'rabbit://${OVN_METADATA_AGENT_TRANSPORT_URL_USER}:${OVN_METADATA_AGENT_TRANSPORT_URL_PASSWORD}@rabbitmq.openstack.svc:5672'
      edpm_ovn_metadata_agent_metadata_agent_ovn_ovn_sb_connection: ${OVN_METADATA_AGENT_SB_CONNECTION}
      edpm_ovn_metadata_agent_metadata_agent_DEFAULT_nova_metadata_host: ${OVN_METADATA_AGENT_NOVA_METADATA_HOST}
      edpm_ovn_metadata_agent_metadata_agent_DEFAULT_metadata_proxy_shared_secret: ${OVN_METADATA_AGENT_PROXY_SHARED_SECRET}
      edpm_ovn_metadata_agent_DEFAULT_bind_host: ${OVN_METADATA_AGENT_BIND_HOST}
      epdm_chrony_ntp_servers:
      - ${CHRONY_NTP_SERVER}
      neutron_physical_bridge_name: br-ex
      neutron_public_interface_name: eth0
      ctlplane_mtu: 1500
      ctlplane_dns_nameservers:
      - 192.168.122.1
      ctlplane_host_routes:
      - ip_netmask: 0.0.0.0/0
        next_hop: 192.168.122.1
      dns_search_domains: []
      ctlplane_ip: 192.168.122.100
      ctlplane_subnet_cidr: '24'
      networks_lower:
        External: external
        InternalApi: internal_api
        Storage: storage
        Tenant: tenant
      role_tags:
      - compute
      - external_bridge
      role_networks:
      - InternalApi
      - Storage
      - Tenant
      external_mtu: 1500
      external_vlan_id: 44
      external_cidr: '24'
      external_ip: '10.10.10.100'
      external_host_routes: []
      internal_api_mtu: 1500
      internal_api_vlan_id: 20
      internal_api_cidr: '24'
      internal_api_ip: '172.17.0.100'
      internal_api_host_routes: []
      storage_mtu: 1500
      storage_vlan_id: 21
      storage_cidr: '24'
      storage_ip: '172.18.0.100'
      storage_host_routes: []
      tenant_mtu: 1500
      tenant_vlan_id: 22
      tenant_cidr: '24'
      tenant_ip: '172.19.0.100'
      tenant_host_routes: []
      networks_all:
      - External
      - InternalApi
      - Storage
      - Tenant
      networks_skip_config: []
EOF_CAT

include_attribute "ndb"
include_attribute "tensorflow"

default['kube-hops']['user']                              = node['install']['user'].empty? ? "kubernetes" : node['install']['user']
default['kube-hops']['user_id']                           = '1523'
default['kube-hops']['group']                             = node['install']['user'].empty? ? "kubernetes" : node['install']['user']
default['kube-hops']['group_id']                          = '1518'
default['kube-hops']['hopsworks_user']                    = "hopsworks"
default['kube-hops']['dir']                               = (node['install']['dir'].empty? ? "/srv" : node['install']['dir']) + "/kube"
default['kube-hops']['user-home']                         = "/home/#{node['kube-hops']['user']}"

default['kube-hops']['device']                            = ""

# General cluster configuration
default['kube-hops']['kubernetes_version']                = "v1.26.1"
default['kube-hops']['kubernetes-cni_version']            = "1.2.0"
default['kube-hops']['cri-tools_version']                 = "1.26.0"
default['kube-hops']['cluster_name']                      = "hops-kubernetes"
default['kube-hops']['image_repo']                        = "registry.k8s.io"


default['kube-hops']['control_plane_imgs_url']            = "#{node['download_url']}/kube/kube-control-plane-#{node['kube-hops']['kubernetes_version']}.tar"

# Binaries configuration
default['kube-hops']['bin']['download_url']               = "#{node['download_url']}/kube/#{node['kube-hops']['kubernetes_version']}/#{node['platform_family']}"
default['kube-hops']['kubernetes-cni']['download_url']    = "#{node['download_url']}/kube/#{node['kube-hops']['kubernetes_version']}/#{node['platform_family']}/cni-plugins-linux-amd64-v#{node['kube-hops']['kubernetes-cni_version']}.tgz"

#cri_dockerd
default['kube-hops']['cri_dockerd']['version']            = "0.3.1"
default['kube-hops']['cri_dockerd']['download_url']       = "#{node['download_url']}/kube/#{node['kube-hops']['kubernetes_version']}/#{node['platform_family']}"

# Resource allocation configuration
default['kube-hops']['docker_max_memory_allocation']      = "8192"
default['kube-hops']['docker_max_cores_allocation']       = "4"
default['kube-hops']['docker_max_gpus_allocation']        = "0"

# Network configuration
default['kube-hops']['cidr']                              = "10.244.0.0/16"
default['kube-hops']['dns_ip']                            = "10.96.0.10"
default['kube-hops']['fallback_dns']                      = ""
default['kube-hops']['flannel']['iface-regex']            = ""
default['kube-hops']['cluster_domain']                    = "cluster.local"
default['kube-hops']['hostname_override']                 = "true"

# Nodes configuration
default['kube-hops']['taints']                            = ""
default['kube-hops']['labels']                            = ""
default['kube-hops']['cri_socket']                        = "unix:///var/run/cri-dockerd.sock"

# Apiserver
default['kube-hops']['apiserver']['port']                 = "6443"

# If true allows to run container also on the master node.
# Useful for development deployment
default['kube-hops']['master']['untaint']                 = "false"

default['kube-hops']['conf_dir'] 						  = "/etc/kubernetes"
default['kube-hops']['kubelet_dir'] 					  = "/var/lib/kubelet"

# Authentication configuration

# CA configuration
default['kube-hops']['pki']['ca_api']                      = ""
default['kube-hops']['pki']['ca_api_user']                 = "glassfish"
default['kube-hops']['pki']['ca_api_group']                = "glassfish"

default['kube-hops']['pki']['ca_keypw']                    = "adminpw"
default['kube-hops']['pki']['rootca_keypw']                = node['hopsworks']['master']['password'].empty? ? "adminpw" : node['hopsworks']['master']['password']
default['kube-hops']['pki']['dir'] 						   = "#{node['kube-hops']['conf_dir']}/pki"
default['kube-hops']['pki']['keysize']					   = 2048
default['kube-hops']['pki']['days']                        = 3650

default['kube-hops']['pki']['verify_hopsworks_cert']       = "true"

default['kube-hops']['hopsworks_cert_pwd']                 = "adminpw"

# Images configuration
default['kube-hops']['pull_policy']                        = "Always"

default['kube-hops']['docker_dir']                         = node['install']['dir'].empty? ? "/var/lib/docker" : "#{node['install']['dir']}/docker"

default['kube-hops']['docker_img_version']                 = node['install']['version']
default['kube-hops']['docker_img_tar_url']                 = node['download_url'] + "/kube/docker-images/#{node['kube-hops']['docker_img_version']}/docker-images.tar"
default['kube-hops']['docker_img_reg_url']                 = ""

#
# KF Serving
#
# VERSIONS:
# Knative -> 1.9.0
# Istio -> 1.16.1
# Cert-manager -> v1.11.0
# KServe -> 0.10.0

default['kube-hops']['kserve']['enabled']               = node['install']['kubernetes']
default['kube-hops']['kserve']['version']               = "0.10.0"
default['kube-hops']['kserve']['base_dir']              = node['kube-hops']['dir'] + "/kserve"
default['kube-hops']['kserve']['img_tar_url']           = node['download_url'] + "/kube/kserve/#{node['install']['version']}/kserve-v#{node['kube-hops']['kserve']['version']}.tgz"

# Istio

default['kube-hops']['istio']['version']                   = "1.16.1"
default['kube-hops']['istio']['base_dir']                  = node['kube-hops']['dir'] + "/istio"
default['kube-hops']['istio']['tar_name']                  = "istio-#{node['kube-hops']['istio']['version']}-linux-amd64"
default['kube-hops']['istio']['home']                      = node['kube-hops']['dir'] + "/#{node['kube-hops']['istio']['tar_name']}"
default['kube-hops']['istio']['tar']                       = node['kube-hops']['dir'] + "/#{node['kube-hops']['istio']['tar_name']}.tar.gz"
default['kube-hops']['istio']['download_url']              = node['download_url'] + "/kube/kserve/#{node['kube-hops']['istio']['tar_name']}.tar.gz"
default['kube-hops']['istio']['ingress_http_port']         = "32080"
default['kube-hops']['istio']['ingress_https_port']        = "32443"
default['kube-hops']['istio']['ingress_status_port']       = "32021"
default['kube-hops']['istio']['ingress_http10']            = "false"

# Knative

default['kube-hops']['knative']['base_dir']                = node['kube-hops']['dir'] + "/knative"
default['kube-hops']['knative']['domain_name']             = "hopsworks.ai"

# Cert-manager

default['kube-hops']['cert-manager']['base_dir']           = node['kube-hops']['dir'] + "/cert-manager"

# Hops-system
# Containing yaml files installed in hops-system namespace. (e.g webhook)

default['kube-hops']['hops-system']['base_dir']            = node['kube-hops']['dir'] + "/hops-system"

# Model serving admission controller

default['kube-hops']['model-serving-webhook']['base_dir']  = node['kube-hops']['hops-system']['base_dir'] + "/model-serving-webhook"
default['kube-hops']['model-serving-webhook']['image']     = "model-serving-webhook:#{node['kube-hops']['docker_img_version']}"
default['kube-hops']['storage-initializer']['image']       = "storage-initializer:#{node['kube-hops']['docker_img_version']}"

# Model serving deployment configuration

default['kube-hops']['serving_node_labels']                = ""
default['kube-hops']['serving_node_tolerations']           = ""
default['kube-hops']['serving_max_memory_allocation']      = "-1"   # no upper limit
default['kube-hops']['serving_max_cores_allocation']       = "-1.0" # no upper limit
default['kube-hops']['serving_max_gpus_allocation']        = "-1"   # no upper limit
default['kube-hops']['serving_max_num_instances']          = "10"   # possible values: >=-1, where -1 means no limit
default['kube-hops']['serving_min_num_instances']          = "-1"   # possible values: >=-1, where -1 means no limit and 0 enforces scale-to-zero when available (e.g., kserve)

# Model serving authenticator

default['kube-hops']['model-serving-authenticator']['base_dir']        = node['kube-hops']['hops-system']['base_dir'] + "/model-serving-authenticator"
default['kube-hops']['model-serving-authenticator']['image']           = "model-serving-authenticator:#{node['kube-hops']['docker_img_version']}"

# Inference logger

default['kube-hops']['inference-logger']['image']                      = "inference-logger:#{node['kube-hops']['docker_img_version']}"

# Sklearnserver

default['kube-hops']['sklearnserver']['image']                         = "sklearnserver"  # tag is appended by kserve with node['kube-hops']['docker_img_version'] (see kserve.yml.erb)

# KServe TF Serving

default['kube-hops']['kserve']['tensorflow']['version']                =  node['tensorflow']['serving']['version']

# Filebeat

default['kube-hops']['filebeat']['image']                              = "filebeat:#{node['kube-hops']['docker_img_version']}"
default['kube-hops']['filebeat']['base_dir']                           = node['kube-hops']['dir'] + "/filebeat"

default['kube-hops']['monitoring']['certs-dir']                        = "#{node['kube-hops']['hops-system']['base_dir']}/hopsmon-certs"
default['kube-hops']['monitoring']['cert-crt']                         = "#{node['kube-hops']['monitoring']['certs-dir']}/hopsmon.crt"
default['kube-hops']['monitoring']['cert-key']                         = "#{node['kube-hops']['monitoring']['certs-dir']}/hopsmon.key"

default['kube-hops']['monitoring']['kube-state-metrics-image-version'] = "v2.7.0"
default['kube-hops']['monitoring']['kube-state-metrics-image-url']     = node['download_url'] + "/kube/monitoring/kube-state-metrics-#{node['kube-hops']['monitoring']['kube-state-metrics-image-version']}.tar"
default['kube-hops']['monitoring']['kube-state-metrics-image-tar']     = "kube-state-metrics-#{node['kube-hops']['monitoring']['kube-state-metrics-image-version']}.tar"
default['kube-hops']['monitoring']['user']                             = "hopsmon"

default['kube-hops']['coredns-autoscaler']['target-deployment']        = "Deployment/coredns"

default['kube-hops']['nvidia-device-plugin']['version']                =  "0.13.0"
default['kube-hops']['nvidia-device-plugin']['url']                    = node['download_url'] + "/kube/nvidia/device-plugin/#{node['kube-hops']['nvidia-device-plugin']['version']}/nvidia-device-plugin.yml"
include_attribute "ndb"

default['kube-hops']['user']                              = node['install']['user'].empty? ? "kubernetes" : node['install']['user']
default['kube-hops']['group']                             = node['install']['user'].empty? ? "kubernetes" : node['install']['user']
default['kube-hops']['hopsworks_user']                    = "hopsworks"
default['kube-hops']['dir']                               = (node['install']['dir'].empty? ? "/srv" : node['install']['dir']) + "/kube"
default['kube-hops']['user-home']                         = "/home/#{node['kube-hops']['user']}"

default['kube-hops']['device']                            = ""

# General cluster configuration
default['kube-hops']['kubernetes_version']                = "v1.18.8"
default['kube-hops']['kubernetes-cni_version']            = "0.8.7"
default['kube-hops']['cri-tools_version']                 = "1.13.0"
default['kube-hops']['cluster_name']                      = "hops-kubernetes"
default['kube-hops']['image_repo']                        = "k8s.gcr.io"

default['kube-hops']['control_plane_imgs_url']            = "#{node['download_url']}/kube/kube-control-plane-#{node['kube-hops']['kubernetes_version']}.tar"

# Binaries configuration
default['kube-hops']['bin']['download_url']               = "#{node['download_url']}/kube/#{node['kube-hops']['kubernetes_version']}/#{node['platform_family']}"


# Resource allocation configuration
default['kube-hops']['docker_max_memory_allocation']      = "8192"
default['kube-hops']['docker_max_cores_allocation']       = "4"
default['kube-hops']['docker_cores_fraction']             = "1.0"
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
# Knative -> 0.17
# Istio -> 1.7.2
# Cert-manager -> 1.2.0
# KFServing -> 0.5.1

default['kube-hops']['kfserving']['enabled']               = node['install']['kubernetes']
default['kube-hops']['kfserving']['version']               = "0.5.1"
default['kube-hops']['kfserving']['base_dir']              = node['kube-hops']['dir'] + "/kfserving"
default['kube-hops']['kfserving']['img_tar_url']           = node['download_url'] + "/kube/kfserving/kfserving-v#{node['kube-hops']['kfserving']['version']}.tgz"

# Istio

default['kube-hops']['istio']['version']                   = "1.7.2"
default['kube-hops']['istio']['base_dir']                  = node['kube-hops']['dir'] + "/istio"
default['kube-hops']['istio']['tar_name']                  = "istio-#{node['kube-hops']['istio']['version']}-linux-amd64"
default['kube-hops']['istio']['home']                      = node['kube-hops']['dir'] + "/#{node['kube-hops']['istio']['tar_name']}"
default['kube-hops']['istio']['tar']                       = node['kube-hops']['dir'] + "/#{node['kube-hops']['istio']['tar_name']}.tar.gz"
default['kube-hops']['istio']['download_url']              = node['download_url'] + "/kube/kfserving/#{node['kube-hops']['istio']['tar_name']}.tar.gz"

# Knative

default['kube-hops']['knative']['base_dir']                = node['kube-hops']['dir'] + "/knative"

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

# Inference logger

default['kube-hops']['inference-logger']['image']             = "inference-logger:#{node['kube-hops']['docker_img_version']}"

# Filebeat

default['kube-hops']['filebeat']['image']                 = "filebeat:#{node['kube-hops']['docker_img_version']}"
default['kube-hops']['filebeat']['base_dir']              = node['kube-hops']['dir'] + "/filebeat"

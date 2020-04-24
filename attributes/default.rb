include_attribute "ndb"

default['kube-hops']['user']                              = node['install']['user'].empty? ? "kubernetes" : node['install']['user']
default['kube-hops']['group']                             = node['install']['user'].empty? ? "kubernetes" : node['install']['user']

default['kube-hops']['cgroup-driver']                     = "systemd"
default['kube-hops']['device']                            = ""

# General cluster configuration
default['kube-hops']['kubernetes_version']                = "v1.12.4"
default['kube-hops']['kubernetes-cni_version']            = "0.6.0"
default['kube-hops']['cri-tools_version']                 = "1.12.0"
default['kube-hops']['cluster_name']                      = "hops-kubernetes"
default['kube-hops']['image_repo']                        = "k8s.gcr.io"

default['kube-hops']['control_plane_imgs_url']            = "#{node['download_url']}/kube/kube-control-plane-#{node['kube-hops']['kubernetes_version']}.tar"

# Binaries configuration
default['kube-hops']['bin']['download_url']               = "#{node['download_url']}/kube/#{node['kube-hops']['kubernetes_version']}/#{node['platform_family']}"


# Resource allocation configuration
default['kube-hops']['docker_max_memory_allocation'] = "8192"
default['kube-hops']['docker_max_cores_allocation']  = "4"
default['kube-hops']['docker_cores_fraction']        = "1.0"
default['kube-hops']['docker_max_gpus_allocation']   = "0"

# Network configuration
default['kube-hops']['cidr']                              = "10.244.0.0/16"
default['kube-hops']['dns_ip']                            = "10.96.0.10"
default['kube-hops']['fallback_dns']                      = ""
default['kube-hops']['flannel']['iface-regex']            = ""
default['kube-hops']['cluster_domain']                    = "cluster.local"

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

default['kube-hops']['registry']                           = "registry.docker-registry.svc.#{node['kube-hops']['cluster_domain']}"
default['kube-hops']['pull_policy']                        = "IfNotPresent"

default['kube-hops']['docker_dir']                         = node['install']['dir'].empty? ? "/var/lib/docker" : "#{node['install']['dir']}/docker"

default['kube-hops']['docker_img_version']                 = node['install']['version'].gsub("-SNAPSHOT", "")
default['kube-hops']['docker_img_tar_url']                 = node['download_url'] + "/kube/docker-images/#{node['kube-hops']['docker_img_version']}/docker-images.tar"
default['kube-hops']['docker_img_reg_url']                 = ""

default['kube-hops']['imgs']['tf']['version']              = default['kube-hops']['docker_img_version']
default['kube-hops']['imgs']['sklearn']['version']         = default['kube-hops']['docker_img_version']
default['kube-hops']['imgs']['filebeat']['version']        = default['kube-hops']['docker_img_version']
default['kube-hops']['imgs']['jupyter']['version']         = default['kube-hops']['docker_img_version']
default['kube-hops']['imgs']['python']['version']          = default['kube-hops']['docker_img_version']
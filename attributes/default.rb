include_attribute "ndb"

default['kube-hops']['user']                              = node['install']['user'].empty? ? "kubernetes" : node['install']['user']
default['kube-hops']['group']                             = node['install']['user'].empty? ? "kubernetes" : node['install']['user']

default['kube-hops']['cgroup-driver']                     = node['platform'].eql?("ubuntu") ? "cgroupfs" : "systemd"

# General cluster configuration
default['kube-hops']['kubernetes_version']                = "v1.12.3"
default['kube-hops']['cluster_name']                      = "hops-kubernetes"
default['kube-hops']['image_repo']                        = "k8s.gcr.io"

# Binaries configuration
default['kube-hops']['bin']['ubuntu-release']             = "00"
default['kube-hops']['bin']['centos-release']             = "0"

# Network configuration
default['kube-hops']['cidr']                              = "10.244.0.0/16"
default['kube-hops']['dns_ip']                            = "10.96.0.10"

# Apiserver
default['kube-hops']['apiserver']['port']                 = "6443"

# If true allows to run container also on the master node.
# Useful for development deployment
default['kube-hops']['master']['untaint']                   = "false"

default['kube-hops']['conf_dir'] 											 	  = "/etc/kubernetes"
default['kube-hops']['kubelet_dir'] 											= "/var/lib/kubelet"

# Authentication configuration

# CA configuration
default['kube-hops']['pki']['ca_api']                      = ""
default['kube-hops']['pki']['ca_api_user']                 = "glassfish"
default['kube-hops']['pki']['ca_api_group']                = "glassfish"

default['kube-hops']['pki']['ca_keypw']                    = "adminpw"
default['kube-hops']['pki']['rootca_keypw']                = node['hopsworks']['master']['password'].empty? ? "adminpw" : node['hopsworks']['master']['password']
default['kube-hops']['pki']['dir'] 											 	 = "#{node['kube-hops']['conf_dir']}/pki"
default['kube-hops']['pki']['keysize']									   = 2048
default['kube-hops']['pki']['days']                        = 3650

default['kube-hops']['pki']['verify_hopsworks_cert']       = "true"

default['kube-hops']['hopsworks_cert_pwd']                 = "adminpw"

default['kube-hops']['docker_img_url']                     = node['download_url'] + "/docker.tgz"
default['kube-hops']['docker_dir']                         = "/var/lib/docker"

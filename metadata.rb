name                    'kube-hops'
maintainer              'Logical Clocks AB'
maintainer_email        'fabio@logicalclocks.com'
license                 ''
description             'Installs/Configures kube-hops-chef'
version                 '3.2.0'

cookbook 'sysctl', '~> 1.0.3'
cookbook 'kernel_module', '~> 1.1.1'
depends 'kagent'
depends 'ndb'
depends 'tensorflow'
depends 'consul'
depends 'hops'
depends 'magic_shell', '~> 1.0.0'
depends 'hopslog'
depends 'kkafka'

recipe 'kube-hops::ca', 'Create and configure Kubernetes\'s CA'
recipe 'kube-hops::master', 'Configure a node as Kubernetes master'
recipe 'kube-hops::node', 'Configure a node as Kubernetes slave'
recipe 'kube-hops::addons', 'Deploy addons on the cluster'
recipe 'kube-hops::hopsworks', 'Configure Hopsworks to use Kubernetes'
recipe 'kube-hops::kserve', 'Configure and install KServe (istio, knative, ...) on Kubernetes'
recipe 'kube-hops::filebeat', 'Configure and install Filebeat for model server logging on Kubernetes'
recipe 'kube-hops::hops-system', 'Create and configure Hops-system namespace in Kubernetes for configuration and core components'
recipe 'kube-hops::hopsmon', "Create and configure certificates for hopsmon"

attribute "kube-hops/user",
          :description =>  "The user running Kubernetes",
          :type => 'string'

attribute "kube-hops/user_id",
          :description =>  "Kubernetes user id. Default: 1523",
          :type => 'string'

attribute "kube-hops/group",
          :description =>  "Group of the user running Kubernetes",
          :type => 'string'

attribute "kube-hops/group_id",
          :description =>  "Kubernetes group id. Default: 1518",
          :type => 'string'

attribute "kube-hops/hopsworks_user",
          :description =>  "The user the hopsworks web-app used to authenticate to Kubernetes",
          :type => 'string'

attribute "kube-hops/device",
          :description =>  "Device plugin to configure for master and nodes, for no device set '' or 'nvidia' for NVIDIA GPUs",
          :type => 'string'

attribute "kube-hops/kubernetes_version",
          :description =>  "kubernetes_version",
          :type => 'string'

attribute "kube-hops/image_repo",
          :description =>  "Repo for default images",
          :type => 'string'

attribute "kube-hops/cidr",
          :description =>  "Cluster address space",
          :type => 'string'

attribute "kube-hops/dns_ip",
          :description =>  "Ip of the DNS service",
          :type => 'string'

attribute "kube-hops/fallback_dns",
          :description =>  "IP of the fallback DNS server for non-cluster resolution",
          :type => 'string'

attribute "kube-hops/flannel/iface-regex",
          :description =>  "iface-regex to configure flannel daemonset",
          :type => 'string'
          
attribute "kube-hops/cluster_domain",
          :description =>  "Kubernetes cluster domain. Default: cluster.local",
          :type => 'string'

attribute "kube-hops/hostname_override",
          :description =>  "Flag to force Kubernetes use FQDN of host as node name. Default: true",
          :type => 'string'

attribute "kube-hops/taints",
          :description =>  "A list of node,taints in the format:  (node1,taint)(node2,taint)",
          :type => 'string'

attribute "kube-hops/labels",
          :description =>  "A list of node,labels in the format:  (node1,label)(node2,label)",
          :type => 'string'

attribute "kube-hops/apiserver/port",
          :description =>  "Port on which the apiserver listens for requests",
          :type => 'string'

attribute "kube-hops/master/untaint",
          :description =>  "Untaint master - meaning that user pods can run on the master node",
          :type => 'string'

attribute "kube-hops/conf_dir",
          :description =>  "Kubernetes configuration dir",
          :type => 'string'

attribute "kube-hops/kubelet_dir",
          :description =>  "Kubelet configuration dir",
          :type => 'string'

attribute "kube-hops/pki/ca_api",
          :description =>  "endpoint of the CA api server (Hopsworks)",
          :type => 'string'

attribute "kube-hops/pki/ca_api_user",
          :description =>  "User running the CA api server",
          :type => 'string'

attribute "kube-hops/pki/ca_api_group",
          :description =>  "Group running the CA api server",
          :type => 'string'

attribute "kube-hops/pki/ca_keypw",
          :description =>  "Password for the kube-ca key",
          :type => 'string'

attribute "kube-hops/pki/rootca_keypw",
          :description =>  "Password for the root-ca key",
          :type => 'string'

attribute "kube-hops/pki/rootca_keypw",
          :description =>  "Password for the root-ca key",
          :type => 'string'

attribute "kube-hops/pki/dir",
          :description =>  "PKI artifacts directory on master and node machines",
          :type => 'string'

attribute "kube-hops/pki/keysize",
          :description =>  "length of keys",
          :type => 'string'

attribute "kube-hops/pki/days",
          :description =>  "Expiration time for certificates",
          :type => 'string'

attribute "kube-hops/pki/verify_hopsworks_cert",
          :description =>  "Verify Hopsworks HTTPS certificate",
          :type => 'string'

attribute "kube-hops/pki/hopsworks_cert_pwd",
          :description =>  "Password for the Hopsworks certificate",
          :type => 'string'

attribute "kube-hops/docker_dir",
          :description =>  "Path on the host machine to be used to store docker containers,imgs,logs",
          :type => 'string'

attribute "kube-hops/docker_img",
          :description =>  "Comma separated list of images to load in the docker registry",
          :type => 'string'

attribute "kube-hops/docker_img_tar_url",
          :description =>  "Remote location of the tar with the images to laod",
          :type => 'string'

attribute "kube-hops/docker_img_reg_url",
          :description =>  "Remote container images registry from which to fetch the images",
          :type => 'string'

attribute "kube-hops/pull_policy",
          :description =>  "Image pull policy for new containers",
          :type => 'string'

attribute "kube-hops/docker_max_memory_allocation",
          :description =>  "Maximum memory that can be allocated for Docker containers",
          :type => 'string'

attribute "kube-hops/docker_max_cores_allocation",
          :description =>  "Maximum number of cores that can be allocated for Docker containers",
          :type => 'string'

attribute "kube-hops/docker_max_gpus_allocation",
          :description =>  "Maximum number of GPUs that can be allocated for Docker containers",
          :type => 'string'

attribute "kube-hops/kserve/enabled",
          :description =>  "Default true. Set to 'false' to disable KServe",
          :type => 'string'

attribute "kube-hops/kserve/img_tar_url",
          :description =>  "Remote container images registry from which to fetch the KServe and dependencies images",
          :type => 'string'

attribute "kube-hops/kserve/tensorflow/version",
          :description =>  "TensorFlow version to use in KServe TensorFlow serving server",
          :type => 'string'

attribute "kube-hops/serving_node_labels",
          :description =>  "The labels used for node selection in model serving pods, in the format key1=value1,key2=value2",
          :type => 'string'

attribute "kube-hops/serving_node_tolerations",
          :description =>  "The tolerations attached to model serving pods, in the format key1:operator1[:value1]:effect1,key2:operator2[:value2]:effect2",
          :type => 'string'

attribute "kube-hops/serving_max_memory_allocation",
          :description =>  "Maximum memory resources to be allocated for model deployments. Possible values are >=-1, where -1 means no limit.",
          :type => 'string'

attribute "kube-hops/serving_max_cores_allocation",
          :description =>  "Maximum cores to be allocated for model deployments. Possible values are >=-1, where -1 means no limit.",
          :type => 'string'

attribute "kube-hops/serving_max_gpus_allocation",
          :description =>  "Maximum gpus to be allocated for model deployments. Possible values are >=-1, where -1 means no limit.",
          :type => 'string'

attribute "kube-hops/serving_max_num_instances",
          :description =>  "Maximum number of replicas in each model deployment. Possible values are >=-1, where -1 means no limit.",
          :type => 'string'

attribute "kube-hops/serving_min_num_instances",
          :description =>  "Minimum number of replicas in each model deployment. Possible values are >=-1, where -1 means no limit and 0 enforces scale-to-zero when available (e.g., kserve).",
          :type => 'string'

attribute "kube-hops/istio/ingress_http_port",
          :description =>  "HTTP port for the istio ingress gateway. The range of valid ports is 30000-32767.",
          :type => 'string'

attribute "kube-hops/istio/ingress_https_port",
          :description =>  "HTTPS port for the istio ingress gateway. The range of valid ports is 30000-32767.",
          :type => 'string'

attribute "kube-hops/istio/ingress_status_port",
          :description =>  "Status port for the istio ingress gateway. The range of valid ports is 30000-32767.",
          :type => 'string'

attribute "kube-hops/istio/ingress_http10",
          :description =>  "Whether to enable HTTP 1.0 in the istio ingress gateway",
          :type => 'string'

attribute "kube-hops/knative/domain_name",
          :description =>  "Domain name for the knative gateway. It is visible in the host header of the inference requests.",
          :type => 'string'

attribute "kube-hops/master/private_ips",
          :description =>  "The private ips for the Kube master server(s)",
          :type => 'array'

attribute "kube-hops/master/public_ips",
          :description =>  "The private ips for the Kube master server(s)",
          :type => 'array'

attribute "kube-hops/nvidia-device-plugin/version",
          :description =>  "The version of the k8s NVIDIA device plugin to install",
          :type => 'string'
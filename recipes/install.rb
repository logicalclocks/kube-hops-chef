# Follow this doc: https://kubernetes.io/docs/tasks/tools/install-kubeadm/
# Create user and group for Kubernetes

group node['kube-hops']['group'] do
  action :create
  not_if "getent group #{node['kube-hops']['group']}"
end

user node['kube-hops']['user'] do
  home "/home/#{node['kube-hops']['user']}"
  gid node['kube-hops']['group']
  system true
  shell "/bin/bash"
  manage_home true
  action :create
  not_if "getent passwd #{node['kube-hops']['user']}"
end


# On all the nodes Kubernetes run, swap needs to be disabled.
# In the setup-chef cookbook we should check that on the nodes dedicated to Kubernetes,
# not swap is enabled.

bash 'disable-swap' do
  user 'root'
  group 'root'
  code <<-EOH
      swapoff -a
      # Edit /etc/fstab to comment out all the swap entries
      # A backup of the old fstab file will be available at /etc/fstab.bck
      sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
    EOH
end

# Install and start Docker

case node['platform']
when 'centos'
  package 'docker'
when 'ubuntu'
  package 'docker.io'
end

if !node['kube-hops']['docker_dir'].eql?("/var/lib/docker")
  directory node['kube-hops']['docker_dir'] do
    owner 'root'
    group 'root'
    mode '0711'
    action :create
  end
end

# Configure Docker
template '/etc/docker/daemon.json' do
  source 'daemon.json.erb'
  owner 'root'
  mode '0755'
  action :create
end

# Install:
# Kubeadm: utility to boostrap a kubernetes cluster
# Kubectl: command line tool to manage a kubernetes cluster
# Kubelet: Kubernetes node agent

# Add repositories
case node['platform']
when 'centos'

  yum_repository 'kubernetes' do
    baseurl 'https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64'
    gpgkey ['https://packages.cloud.google.com/yum/doc/yum-key.gpg',
            'https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg']
    action :create
  end

  # Disabling SELinux by running setenforce 0 is required to allow containers to access
  # the host filesystem, which is required by pod networks for example.
  # You have to do this until SELinux support is improved in the kubelet.
  bash 'disable_selinux' do
    user 'root'
    group 'root'
    code <<-EOH
      setenforce 0
      sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    EOH
  end

when 'ubuntu'
  package ['apt-transport-https','curl']

  apt_repository 'kubernetes' do
    uri 'http://apt.kubernetes.io/'
    distribution 'kubernetes-xenial'
    components ['main']
    key 'https://packages.cloud.google.com/apt/doc/apt-key.gpg'
  end

end

# Install packages
package 'kubeadm' do
  version node['kube-hops']['kubernetes_version'] 
end

package 'kubelet' do
  version node['kube-hops']['kubernetes_version'] 
end

package 'kubectl' do
  version node['kube-hops']['kubernetes_version'] 
end


# Make sure that Kubernetes cgroup's driver matches the Docker one
bash 'cgroup-driver-sed' do
  user 'root'
  group 'root'
  code <<-EOH
    sed -i "s/cgroup-driver=systemd/cgroup-driver=#{node['kube-hops']['cgroup-driver']}/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  EOH
end

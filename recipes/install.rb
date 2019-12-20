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

case node['platform_family']
when 'rhel'
  package 'docker'
when 'ubuntu'
  package 'docker.io'
end

if !node['kube-hops']['docker_dir'].eql?("/var/lib/docker")
  directory node['kube-hops']['docker_dir'] do
    owner 'root'
    group 'root'
    mode '0711'
    recursive true
    action :create
  end
end

# Configure Docker
# On CENTOS docker comes down already with a basic configuration which might conflict with the 
# daemon.json configuration we template here. So we replace the configuration file
if node['platform_family'].eql?("rhel")
  storage_opts = "overlay2.override_kernel_check=true"
 
  template '/lib/systemd/system/docker.service' do
    source 'docker.service.erb'
    owner 'root'
    mode '0755'
    action :create
  end

  template '/etc/sysconfig/docker' do
    source 'docker.erb'
    owner 'root'
    mode '0755'
    action :create
  end
end

template '/etc/docker/daemon.json' do
  source 'daemon.json.erb'
  owner 'root'
  mode '0755'
  variables ({
    'storage_opts': storage_opts
  })
  action :create
end

# Install:
# Kubeadm: utility to boostrap a kubernetes cluster
# Kubectl: command line tool to manage a kubernetes cluster
# Kubelet: Kubernetes node agent

# Download  and install binaries
kubernetes_version = node['kube-hops']['kubernetes_version'][1..-1]
package_type = node['platform_family'].eql?("debian") ? "_amd64.deb" : ".x86_64.rpm"
packages = ["cri-tools-#{node['kube-hops']['cri-tools_version']}#{package_type}", "kubelet-#{kubernetes_version}#{package_type}", "kubernetes-cni-#{node['kube-hops']['kubernetes-cni_version']}#{package_type}", "kubectl-#{kubernetes_version}#{package_type}", "kubeadm-#{kubernetes_version}#{package_type}"]

packages.each do |pkg|
  remote_file "#{Chef::Config['file_cache_path']}/#{pkg}" do
    source "#{node['kube-hops']['bin']['download_url']}/#{pkg}"
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
end

if node['kube-hops']['device'].eql?("nvidia")
  nvidia_docker_packages = ["libnvidia-container1-1.0.5-1#{package_type}", "libnvidia-container-tools-1.0.5-1#{package_type}", "nvidia-container-toolkit-1.0.5-2#{package_type}", "nvidia-container-runtime-2.0.0-1.docker1.13.1#{package_type}"]
  nvidia_docker_packages.each do |pkg|
    remote_file "#{Chef::Config['file_cache_path']}/#{pkg}" do
      source "#{node['download_url']}/kube/nvidia/#{pkg}"
      owner 'root'
      group 'root'
      mode '0755'
      action :create
    end
  end
  packages.concat(nvidia_docker_packages)
end

# Install packages & Platform specific configuration
case node['platform_family']
when 'rhel'

  bash "install_pkgs" do
    user 'root'
    group 'root'
    cwd Chef::Config['file_cache_path']
    code <<-EOH
        yum install -y #{packages.join(" ")}
    EOH
    not_if "yum list installed kubeadm-#{kubernetes_version}"
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

when 'debian'

  bash "install_pkgs" do
    user 'root'
    group 'root'
    cwd Chef::Config['file_cache_path']
    code <<-EOH
        apt-get install -y #{packages.join(" ")}
    EOH
  end
end


# Make sure that Kubernetes cgroup's driver matches the Docker one
bash 'cgroup-driver-sed' do
  user 'root'
  group 'root'
  code <<-EOH
    sed -i "s/cgroup-driver=systemd/cgroup-driver=#{node['kube-hops']['cgroup-driver']}/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  EOH
end

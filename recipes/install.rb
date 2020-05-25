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

when 'debian'

  bash "install_pkgs" do
    user 'root'
    group 'root'
    cwd Chef::Config['file_cache_path']
    code <<-EOH
        apt-get install -y ./#{packages.join(" ./")}
    EOH
  end
end

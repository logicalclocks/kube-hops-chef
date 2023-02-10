# Follow this doc: https://kubernetes.io/docs/tasks/tools/install-kubeadm/
# Create user and group for Kubernetes

group node['kube-hops']['group'] do
  gid node['kube-hops']['group_id']
  action :create
  not_if "getent group #{node['kube-hops']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['kube-hops']['user'] do
  home "/home/#{node['kube-hops']['user']}"
  uid node['kube-hops']['user_id']
  gid node['kube-hops']['group']
  system true
  shell "/bin/bash"
  manage_home true
  action :create
  not_if "getent passwd #{node['kube-hops']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
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

# Install conntrack required by Kubernetes Version ≥ 1.18. https://github.com/kubesphere/kubekey#requirements-and-recommendations
package 'conntrack' do
  retries 10
  retry_delay 30
end

# Install:
# Kubeadm: utility to boostrap a kubernetes cluster
# Kubectl: command line tool to manage a kubernetes cluster
# Kubelet: Kubernetes node agent

# Download  and install binaries
kubernetes_version = node['kube-hops']['kubernetes_version'][1..-1]
packages = ["crictl-#{node['kube-hops']['cri-tools_version']}", "kubelet-#{kubernetes_version}", "kubectl-#{kubernetes_version}", "kubeadm-#{kubernetes_version}"]
kubernetes_cni = "kubernetes-cni"

packages.each do |pkg|
  remote_file "#{Chef::Config['file_cache_path']}/#{pkg}" do
    source "#{node['kube-hops']['bin']['download_url']}/#{pkg}"
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
end

packages.each do |pkg|
  bash "install_pkg_#{pkg}" do
    user 'root'
    group 'root'
    cwd Chef::Config['file_cache_path']
    code <<-EOH
        echo "Installing package #{pkg}"
        bin=#{pkg.gsub("-"+kubernetes_version, "").gsub("-"+node['kube-hops']['cri-tools_version'], "")}
        mv #{pkg} /usr/bin/$bin
        chmod +x /usr/bin/$bin
    EOH
  end
end

case node['platform_family']
when "rhel"
  systemd_path = "/usr/lib/systemd/system"
when "debian"
  systemd_path = "/lib/systemd/system"
end

#create a service for kubelet
#the service will not be able to start until cri-dockerd is installed. It will be restarted later by kubeadmin
kubelet_service = "kubelet"
kubelet_systemd_script = "#{systemd_path}/#{kubelet_service}.service"
kubelet_dropin_service_dir = "/etc/systemd/system/kubelet.service.d"

template kubelet_systemd_script do
  source "#{kubelet_service}-service.erb"
  owner "root"
  group "root"
end

directory kubelet_dropin_service_dir do
  owner "root"
  group "root"
  mode "0755"
  action :create
  not_if { ::File.directory?(kubelet_dropin_service_dir) }
end

template "#{kubelet_dropin_service_dir}/10-kubeadm.conf" do
  source "kubelet-service-dropin.erb"
  owner "root"
  group "root"
end

bash "enable_and_start_kubelet_service" do
  user 'root'
  group 'root'
  code <<-EOH
    systemctl daemon-reload
    systemctl enable #{kubelet_service}
    systemctl start #{kubelet_service}
  EOH
end

remote_file "#{Chef::Config['file_cache_path']}/#{kubernetes_cni}" do
  source "#{node['kube-hops']['kubernetes-cni']['download_url']}"
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

#create the cni installation dir in /opt
directory "/opt/cni" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

directory "/opt/cni/bin" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

bash "install_cni_plugins" do
  user 'root'
  group 'root'
  cwd Chef::Config['file_cache_path']
  code <<-EOH
    tar xvf #{kubernetes_cni} -C /opt/cni/bin
    chmod +x /opt/cni/bin/*
  EOH
end
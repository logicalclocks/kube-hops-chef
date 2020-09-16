# For Flannel (overlay network) to work we need to pass bridged IPv4 traffic to iptables’ chains
if node['platform_family'].eql?('rhel')
  # For centos, at least on a VM we need to load some kernel modules
  kernel_module 'bridge' do
    action :install
  end

  kernel_module 'br_netfilter' do
    action :install
  end
end

sysctl_param 'net.bridge.bridge-nf-call-iptables' do
  value 1
end

# Start the docker deamon
service 'docker' do
  action [:enable, :start]
end

# Install g++ to be able to install http-cookie gem
case node['platform_family']
when 'rhel'
  package 'gcc-c++'
when 'debian'
  package 'g++'
end

# If AirGapped installation, download control plane images from download_url and load them 
if node['kube-hops']['image_repo'].eql?("")
  control_plane_images = "#{Chef::Config['file_cache_path']}/#{::File.basename(node['kube-hops']['control_plane_imgs_url'])}"
  remote_file control_plane_images do
    source node['kube-hops']['control_plane_imgs_url']
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  bash 'load_control_plane_imgs' do
    user 'root'
    group 'root'
    code <<-EOH
      docker load < #{control_plane_images}
    EOH
    action :run
  end
end

# Install gem as helper to send Hopsworks requrests to sign certificates
chef_gem 'http-cookie'

hopsworks_ip = private_recipe_ip('hopsworks', 'default')
hopsworks_https_port = 8181
if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('https') and node['hopsworks']['https'].attribute?('port')
    hopsworks_https_port = node['hopsworks']['https']['port']
  end
end

node.override['kube-hops']['pki']['ca_api'] = "#{hopsworks_ip}:#{hopsworks_https_port}"

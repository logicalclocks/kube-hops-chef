# Change machine DNS to use the Kubernetes internal one
# It will fall back to the specified dns server if you look for logicalclocks.com

# Make a backup before overwriting it.
remote_file "/etc/resolv.conf.bck" do 
  owner "root"
  group "root"
  source "file:///etc/resolv.conf"
  mode "644"
  action :create_if_missing
end

node.override['resolver']['nameservers'] = ["#{node['kube-hops']['dns_ip']}"]
include_recipe "resolver::default"

# Add ca.crt to /etc/docker/cert.d/docker-regstry for docker
# to be able to pull images from the private registry
directory '/etc/docker/certs.d/' do
  owner   'root'
  group   'root'
  action  :create
end

directory '/etc/docker/certs.d/registry.docker-registry.svc.cluster.local' do
  owner   'root'
  group   'root'
  action  :create
end

remote_file '/etc/docker/certs.d/registry.docker-registry.svc.cluster.local/ca.crt' do
  source "file://#{node['kube-hops']['pki']['dir']}/ca.crt"
  owner  'root'
  group  'root'
end

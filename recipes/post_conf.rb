# Change machine DNS to use the Kubernetes internal one
# It will fall back to something if you look for logicalclocks.com
# Not sure how to configure the fallback yethk
node.override['resolver']['nameservers'] = ["#{node['kube-hops']['dns_ip']}"]
include_recipe "resolver::default"

# Add ca.crt to /etc/docker/cert.d/docker-regstry for docker
# to be able to pull images from the private registry
directory '/etc/docker/cert.d/' do
  owner   'root'
  group   'root'
  action  :create
end

directory '/etc/docker/cert.d/registry.docker-registry.svc.cluster.local' do
  owner   'root'
  group   'root'
  action  :create
end

remote_file '/etc/docker/cert.d/registry.docker-registry.svc.cluster.local/ca.crt' do
  source "file://#{node['kube-hops']['pki']['dir']}/ca.crt"
  owner  'root'
  group  'root'
end

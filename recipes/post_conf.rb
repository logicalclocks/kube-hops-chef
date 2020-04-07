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

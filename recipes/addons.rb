# Deploy RBAC rule for Hopsworks user

if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('user')
    node.override['kube-hops']['pki']['ca_api_user'] = node['hopsworks']['user']
  end
end

template "#{node['kube-hops']['conf_dir']}/hopsworks-rbac.yaml" do
  source "hopsworks-rbac.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply_hopsworks_rbac' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['conf_dir']}/hopsworks-rbac.yaml"
end

# TODO (Fabio) : authentication and deploy default images
hopsworks_ip = private_recipe_ip('hopsworks', 'default')
hopsworks_https_port = 8181
if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('secure_port')
    hopsworks_https_port = node['hopsworks']['secure_port']
  end
end

node.override['kube-hops']['pki']['ca_api'] = "#{hopsworks_ip}:#{hopsworks_https_port}"


if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('user')
    node.override['kube-hops']['pki']['ca_api_user'] = node['hopsworks']['user']
  end
end

kube_hops_certs 'domain' do
  path        "/home/#{node['kube-hops']['user']}"
  owner       node['kube-hops']['user']
  group       node['kube-hops']['group']
  subject     "/CN=registry.docker-registry.svc.cluster.local"
  not_if      { ::File.exist?("/home/#{node['kube-hops']['user']}/domain.crt") }
end

crt = ""
key = ""

# Read the content of the files
ruby_block 'read_crypto' do
  block do
    require 'base64'

    crt = ::File.read("/home/#{node['kube-hops']['user']}/domain.crt")
    crt = ::Base64.strict_encode64(crt)

    key = ::File.read("/home/#{node['kube-hops']['user']}/domain.key")
    key = ::Base64.strict_encode64(key)
  end
end

# TODO (Fabio) : TLS, authentication and deploy default images
template "#{node['kube-hops']['conf_dir']}/registry.yaml" do
  source "registry.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  variables( lazy {
      h = {}
      h['crt'] = crt
      h['key'] = key
      h
    })
end

kube_hops_kubectl 'deploy_docker_registry' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['conf_dir']}/registry.yaml"
end

# Push default images on the registry
remote_file "/home/#{node['kube-hops']['user']}/docker-images.tgz" do
  source node['kube-hops']['docker_img_url']
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0644"
  action :create
end

directory "/home/#{node['kube-hops']['user']}/docker-images" do
  recursive true
  action :delete
  only_if  { ::File.directory?("/home/#{node['kube-hops']['user']}/docker-images") }
end

bash "extract" do
  user node['kube-hops']['user']
  cwd "/home/#{node['kube-hops']['user']}"
  code <<-EOH
    tar xf docker-images.tgz
  EOH
end

bash "build_and_push" do
  user "root"
  cwd "/home/#{node['kube-hops']['user']}/docker-images"
  code <<-EOH
    for image in */ ; do
      cd "$image"
      docker build . -t registry.docker-registry.svc.cluster.local/${image%/}
      docker push registry.docker-registry.svc.cluster.local/${image%/}
    done
  EOH
end

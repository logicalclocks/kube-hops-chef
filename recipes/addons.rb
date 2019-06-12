# Deploy RBAC rule for Hopsworks user
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
  if node['hopsworks'].attribute?('https') and node['hopsworks']['https'].attribute?('port')
    hopsworks_https_port = node['hopsworks']['https']['port']
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
if not node['kube-hops']['docker_img_tar_url'].eql?("")
  hops_images = "#{Chef::Config['file_cache_path']}/docker-images.tar"
  remote_file hops_images do
    source node['kube-hops']['docker_img_tar_url']
    owner node['kube-hops']['user']
    group node['kube-hops']['group']
    mode "0644"
  end

  bash "load" do
    user 'root'
    group 'root'
    code <<-EOH
      docker load < #{hops_images}
    EOH
  end
else
  # TODO(Fabio): pull from registry
end

bash "tag_and_push" do
    user "root"
    code <<-EOH
      set -e
      for image in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep #{node['kube-hops']['docker_img_version']})
      do
        img_name=(${image//\// })
        docker tag $image #{node['kube-hops']['registry']}/${img_name[1]}
        docker push #{node['kube-hops']['registry']}/${img_name[1]}
      done
    EOH
end

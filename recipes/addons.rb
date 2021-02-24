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

registry_host=consul_helper.get_service_fqdn("registry")
bash "tag_and_push" do
    user "root"
    code <<-EOH
      set -e
      for image in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep #{node['kube-hops']['docker_img_version']})
      do
        img_name=(${image//\// })
        docker tag $image #{registry_host}:#{node['hops']['docker']['registry']['port']}/${img_name[1]}
        docker push #{registry_host}:#{node['hops']['docker']['registry']['port']}/${img_name[1]}
      done
    EOH
end

if node['kube-hops']['kfserving']['enabled'].casecmp?("true")
  include_recipe "kube-hops::kfserving"
end

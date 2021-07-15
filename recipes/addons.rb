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

if node['kube-hops']['docker_img_reg_url'].eql?("")
  node.override['kube-hops']['docker_img_reg_url'] = registry_host + ":#{node['hops']['docker']['registry']['port']}"
end

include_recipe "kube-hops::hops-system"
include_recipe "kube-hops::filebeat"

# Apply node taints
node['kube-hops']['taints'].split(")").each do |node_taint|
  node_taint_splits = node_taint[1, node_taint.length-1].split(",")
  node_name = node_taint_splits[0]
  taint = node_taint_splits[1]

  kube_hops_kubectl "#{taint}" do
    user node['kube-hops']['user']
    group node['kube-hops']['group']
    k8s_node node_name
    action :taint
  end
end

# Apply node labels
node['kube-hops']['labels'].split(")").each do |node_label|
  node_label_splits = node_label[1, node_label.length-1].split(",")
  node_name = node_label_splits[0]
  label = node_label_splits[1]

  kube_hops_kubectl "#{label}" do
    user node['kube-hops']['user']
    group node['kube-hops']['group']
    k8s_node node_name
    action :label
  end
end

if node['kube-hops']['kfserving']['enabled'].casecmp?("true")
  include_recipe "kube-hops::kfserving"
end

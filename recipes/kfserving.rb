#
# Install KFServing and dependencies
#

# Load kfserving images

kfserving_images = "#{Chef::Config['file_cache_path']}/kfserving-v#{node['kube-hops']['kfserving']['version']}.tgz"
remote_file kfserving_images do
  source node['kube-hops']['kfserving']['img_tar_url']
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0644"
end

bash "load" do
  user 'root'
  group 'root'
  code <<-EOH
    docker load < #{kfserving_images}
  EOH
end

# Istio

remote_file "#{node['kube-hops']['istio']['tar']}" do
  source node['kube-hops']['istio']['download_url']
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0700"
end

directory "#{node['kube-hops']['istio']['home']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0700"
  action :create
end

bash 'extract-istio' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  cwd "#{node['kube-hops']['dir']}"
  code <<-EOH
    set -e
    tar zxf #{node['kube-hops']['istio']['tar']} -C #{node['kube-hops']['istio']['home']}
    chmod 0700 #{node['kube-hops']['istio']['home']}
    EOH
end

file "#{node['kube-hops']['istio']['tar']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  action :delete
end

link "#{node['kube-hops']['istio']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0700"
  to               "#{node['kube-hops']['istio']['home']}"
  link_type        :symbolic
end

template "#{node['kube-hops']['istio']['base_dir']}/istio-operator.yaml" do
  source "istio-operator.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

bash 'apply-istio' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']) })
  cwd "#{node['kube-hops']['istio']['base_dir']}"
  code <<-EOH
    istio-#{node['kube-hops']['istio']['version']}/bin/istioctl install -f istio-operator.yaml
    EOH
end

# Knative

directory "#{node['kube-hops']['knative']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

template "#{node['kube-hops']['knative']['base_dir']}/knative-serving-crds.yaml" do
  source "knative-serving-crds.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "#{node['kube-hops']['knative']['base_dir']}/knative-serving.yaml" do
  source "knative-serving.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "#{node['kube-hops']['knative']['base_dir']}/knative-istio.yaml" do
  source "knative-istio.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply-knative-serving-crds' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['knative']['base_dir']}/knative-serving-crds.yaml"
end

kube_hops_kubectl 'apply-knative-serving' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['knative']['base_dir']}/knative-serving.yaml"
end

kube_hops_kubectl 'apply-knative-istio-controller' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['knative']['base_dir']}/knative-istio.yaml"
end

# Cert-manager

directory "#{node['kube-hops']['cert-manager']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

template "#{node['kube-hops']['cert-manager']['base_dir']}/cert-manager.yaml" do
  source "cert-manager.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply-cert-manager' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  flags "--validate=false"
  url "#{node['kube-hops']['cert-manager']['base_dir']}/cert-manager.yaml"
end

bash 'wait-for-cert-manager' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']) })
  code <<-EOH
    kubectl wait --for=condition=Ready pods --all -n cert-manager --timeout=60s
    sleep 15s
    EOH
end

# KFServing

directory "#{node['kube-hops']['kfserving']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

template "#{node['kube-hops']['kfserving']['base_dir']}/kfserving.yaml" do
  source "kfserving.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply-kfseving' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['kfserving']['base_dir']}/kfserving.yaml"
end

# Model Serving Admission Controller

directory "#{node['kube-hops']['model-serving-webhook']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

template "#{node['kube-hops']['model-serving-webhook']['base_dir']}/model-serving-webhook.yaml.template" do
  source "model-serving-webhook.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_certs 'model-serving-webhook' do
  path        node['kube-hops']['model-serving-webhook']['base_dir']
  subject     "/CN=model-serving-webhook.hops-system.svc"
  not_if      { ::File.exist?("#{node['kube-hops']['model-serving-webhook']['base_dir']}/model-serving-webhook.crt") }
end

bash 'configure-model-serving-webhook-tls' do
  user 'root'
  group 'root'
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']) })
  cwd "#{node['kube-hops']['model-serving-webhook']['base_dir']}"
  code <<-EOH
    set -e
    service_name="model-serving-webhook"
    
    # Create yaml files
    kubectl -n hops-system create secret tls ${service_name}-tls \
        --cert "${service_name}.crt" \
        --key "${service_name}.key" \
        --dry-run=client --output=yaml \
        > ${service_name}-tls.yaml

    # Add the CA Bundle
    ca_pem_b64="$(openssl base64 -A <"${service_name}.crt")"
    sed -e 's@${CA_PEM_B64}@'"$ca_pem_b64"'@g' <"${service_name}.yaml.template" \
        > ${service_name}.yaml
    EOH
  not_if { File.exist? "#{node['kube-hops']['model-serving-webhook']['base_dir']}/model-serving-webhook.yaml" }
end

kube_hops_kubectl 'apply-model-serving-webhook-tls' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['model-serving-webhook']['base_dir']}/model-serving-webhook-tls.yaml"
end

kube_hops_kubectl 'apply-model-serving-webhook' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['model-serving-webhook']['base_dir']}/model-serving-webhook.yaml"
end

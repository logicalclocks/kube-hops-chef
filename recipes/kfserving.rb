#
# Install KFServing and dependencies
#

directory "#{node['kube-hops']['dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0700"
  action :create
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

# Hops system config

directory "#{node['kube-hops']['hops-system']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

hopsworks_api_fqdn = consul_helper.get_service_fqdn("hopsworks.glassfish")
hopsworks_api_port = 8181
if node.attribute?('hopsworks') and node['hopsworks'].attribute?('https') and node['hopsworks']['https'].attribute?('port')
  hopsworks_api_port = node['hopsworks']['https']['port']
end

template "#{node['kube-hops']['hops-system']['base_dir']}/hops-system.yaml" do
  source "hops-system.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  variables({
    'hopsworks_fqdn': hopsworks_api_fqdn,
    'hopsworks_port': hopsworks_api_port
  })
end

kube_hops_kubectl 'apply-hops-system' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['hops-system']['base_dir']}/hops-system.yaml"
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

bash 'configure-model-serving-webhook-tls' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']) })
  cwd ::Dir.home(node['kube-hops']['user'])
  code <<-EOH
    namespace="hops-system"
    service_name="model-serving-webhook"
    webhook_dir="model-serving-webhook"
    keys_dir="$(mktemp -d)"
    chmod 0700 "$keys_dir"

    # Generate the CA cert and private key
    openssl req -nodes -new -x509 -keyout ${keys_dir}/ca.key -out ${keys_dir}/ca.crt -subj "/CN=Admission Controller Model Serving CA"

    # Generate the private key for the webhook server
    openssl genrsa -out ${keys_dir}/${service_name}-tls.key 2048

    # Generate a Certificate Signing Request (CSR) for the private key, and sign it with the private key of the CA.
    openssl req -new -key ${keys_dir}/${service_name}-tls.key -subj "/CN=$service_name.$namespace.svc" |
      openssl x509 -req -CA ${keys_dir}/ca.crt -CAkey ${keys_dir}/ca.key -CAcreateserial -out ${keys_dir}/${service_name}-tls.crt

    # Create yaml files
    kubectl -n $namespace create secret tls ${service_name}-tls \
        --cert "${keys_dir}/${service_name}-tls.crt" \
        --key "${keys_dir}/${service_name}-tls.key" \
        --dry-run=client --output=yaml \
        > ${webhook_dir}/${service_name}-tls.yaml
    ca_pem_b64="$(openssl base64 -A <"${keys_dir}/ca.crt")"
    sed -e 's@${CA_PEM_B64}@'"$ca_pem_b64"'@g' <"${webhook_dir}/${service_name}.yaml.template" \
        > ${webhook_dir}/${service_name}.yaml

    rm -rf "$keys_dir"
    EOH
  not_if { File.exist? "/home/#{node['kube-hops']['user']}/model-serving-webhook/model-serving-webhook.yaml" }

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

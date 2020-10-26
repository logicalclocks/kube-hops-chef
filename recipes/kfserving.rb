# Install KFServing and required tools

# Istio

bash 'install-istioctl' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']) })
  cwd ::Dir.home(node['kube-hops']['user'])
  code <<-EOH
    wget -nc #{node['kube-hops']['istio_url']}
    tar zxf istio-#{node['kube-hops']['istio_version']}-linux-amd64.tar.gz
    rm -f istio
    ln -s istio-#{node['kube-hops']['istio_version']} istio
    EOH
  not_if { File.exist? "/home/#{node['kube-hops']['user']}/istio-#{node['kube-hops']['istio_version']}/bin/istioctl" }
end

template "/home/#{node['kube-hops']['user']}/istio-operator.yaml" do
  source "istio-operator.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

bash 'apply-istio' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']) })
  cwd ::Dir.home(node['kube-hops']['user'])
  code <<-EOH
    istio/bin/istioctl install -f istio-operator.yaml
    EOH
end

# Knative

directory "/home/#{node['kube-hops']['user']}/knative" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

template "/home/#{node['kube-hops']['user']}/knative/knative-serving-crds.yaml" do
  source "knative-serving-crds.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "/home/#{node['kube-hops']['user']}/knative/knative-serving.yaml" do
  source "knative-serving.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "/home/#{node['kube-hops']['user']}/knative/knative-istio.yaml" do
  source "knative-istio.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply-knative-serving-crds' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "/home/#{node['kube-hops']['user']}/knative/knative-serving-crds.yaml"
end

kube_hops_kubectl 'apply-knative-serving' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "/home/#{node['kube-hops']['user']}/knative/knative-serving.yaml"
end

kube_hops_kubectl 'apply-knative-istio-controller' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "/home/#{node['kube-hops']['user']}/knative/knative-istio.yaml"
end

# Cert-manager

template "/home/#{node['kube-hops']['user']}/cert-manager.yaml" do
  source "cert-manager.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply-cert-manager' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  flags "--validate=false"
  url "/home/#{node['kube-hops']['user']}/cert-manager.yaml"
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

template "/home/#{node['kube-hops']['user']}/kfserving.yaml" do
  source "kfserving.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply-kfseving' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "/home/#{node['kube-hops']['user']}/kfserving.yaml"
end

# Hops system config

hopsworks_endpoint = node['kube-hops']['pki']['ca_api'].split(':', 2)
hopsworks_ip = hopsworks_endpoint.first
hopsworks_port = hopsworks_endpoint.last

template "/home/#{node['kube-hops']['user']}/hops-system.yaml" do
  source "hops-system.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  variables({
    'hopsworks_ip': hopsworks_ip,
    'hopsworks_port': hopsworks_port
  })
end

kube_hops_kubectl 'apply-hops-system' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "/home/#{node['kube-hops']['user']}/hops-system.yaml"
end

# Model Serving Admission Controller

directory "/home/#{node['kube-hops']['user']}/model-serving-webhook" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

template "/home/#{node['kube-hops']['user']}/model-serving-webhook/model-serving-webhook.yaml.template" do
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
end

kube_hops_kubectl 'apply-model-serving-webhook' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "/home/#{node['kube-hops']['user']}/model-serving-webhook"
end

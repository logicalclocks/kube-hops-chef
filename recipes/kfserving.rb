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

kube_certs = "#{node['certs']['dir']}/kube/certs"
kube_private = "#{node['certs']['dir']}/kube/private"

bash 'configure-model-serving-webhook-tls' do
  user 'root'
  group 'root'
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']),
                 'KEYPW' => node['kube-hops']['pki']['ca_keypw'] })
  cwd "#{node['kube-hops']['model-serving-webhook']['base_dir']}"
  code <<-EOH
    set -e

    namespace="hops-system"
    service_name="model-serving-webhook"
    tmp_certs="$(mktemp -d)"
    chmod 0700 "$tmp_certs"

    # Generate the private key for the webhook server
    [ -f ${tmp_certs}/${service_name}-tls.key.pem ] || openssl genrsa -out ${tmp_certs}/${service_name}-tls.key.pem 4096

    # Generate a Certificate Signing Request (CSR) for the private key
    [ -f ${tmp_certs}/${service_name}-tls.csr.pem ] || openssl req -new -key ${tmp_certs}/${service_name}-tls.key.pem -subj "/CN=$service_name.$namespace.svc" \
      -out ${tmp_certs}/${service_name}-tls.csr.pem -passout pass:${KEYPW}

    # Sign CSR
    [ -f ${tmp_certs}/${service_name}-tls.crt.pem ] || openssl x509 -req -CA #{kube_certs}/kube-ca.cert.pem -CAkey #{kube_private}/kube-ca.key.pem -CAcreateserial \
      -passin pass:${KEYPW} -in ${tmp_certs}/${service_name}-tls.csr.pem -out ${tmp_certs}/${service_name}-tls.crt.pem

    # Create yaml files
    kubectl -n $namespace create secret tls ${service_name}-tls \
        --cert "${tmp_certs}/${service_name}-tls.crt.pem" \
        --key "${tmp_certs}/${service_name}-tls.key.pem" \
        --dry-run=client --output=yaml \
        > ${service_name}-tls.yaml

    ca_pem_b64="$(openssl base64 -A <"${tmp_certs}/${service_name}-tls.crt.pem")"
    sed -e 's@${CA_PEM_B64}@'"$ca_pem_b64"'@g' <"${service_name}.yaml.template" \
        > ${service_name}.yaml

    rm -rf "$tmp_certs"
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

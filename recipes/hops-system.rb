#
# Install hops-system
#
# Common namespace for core components such configmaps, filebeat or model-serving-webhook

# Create dirs

directory "#{node['kube-hops']['dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0700"
  action :create
end

directory "#{node['kube-hops']['hops-system']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

# Install namespace

hopsworks_api_fqdn = consul_helper.get_service_fqdn("hopsworks.glassfish")
hopsworks_api_port = 8181
if node.attribute?('hopsworks') and node['hopsworks'].attribute?('https') and node['hopsworks']['https'].attribute?('port')
  hopsworks_api_port = node['hopsworks']['https']['port']
end

kafka_brokers = consul_helper.get_service_fqdn("kafka") + ":#{node['kkafka']['broker']['port']}"

template "#{node['kube-hops']['hops-system']['base_dir']}/hops-system.yaml" do
  source "hops-system.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  variables({
    'hopsworks_fqdn': hopsworks_api_fqdn,
    'hopsworks_port': hopsworks_api_port,
    'kafka_brokers': kafka_brokers
  })
end

kube_hops_kubectl 'apply-hops-system' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['hops-system']['base_dir']}/hops-system.yaml"
end

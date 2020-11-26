#
# Install Filebeat
#
# Model server logging for both KFServing and K8s deployments

logstash_fqdn = consul_helper.get_service_fqdn("logstash")
logstash_serving_endpoint = logstash_fqdn + ":#{node['logstash']['beats']['serving_port']}"
serving_log_name = "serving"

directory "#{node['kube-hops']['filebeat']['base_dir']}" do
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode '0700'
  action :create
end

template "#{node['kube-hops']['filebeat']['base_dir']}/filebeat.yaml" do
  source "filebeat-serving.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  variables({ 
    :logstash_endpoint => logstash_serving_endpoint,
    :log_name => serving_log_name
  })
end

kube_hops_kubectl 'apply-filebeat' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['filebeat']['base_dir']}/filebeat.yaml"
end
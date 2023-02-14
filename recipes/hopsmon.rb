#Generate and sign certificates for hopsmon
hopsworks_ip = private_recipe_ip('hopsworks', 'default')
hopsworks_https_port = 8182

if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('https') and node['hopsworks']['https'].attribute?('port')
    hopsworks_https_port = node['hopsworks']['https']['port']
  end
end

node.override['kube-hops']['pki']['ca_api'] = "#{hopsworks_ip}:#{hopsworks_https_port}"
hopsmon_kube_certs_dir = "#{node['kube-hops']['monitoring']['certs-dir']}"

directory hopsmon_kube_certs_dir do
  owner node['kube-hops']['user']
  group node['kube-hops']['user']
  mode '0700'
  action :create
  not_if { ::File.directory?(node['kube-hops']['monitoring']['certs-dir']) }
end

kube_hops_certs 'hopsmon' do
  path        hopsmon_kube_certs_dir
  subject     "/CN=hopsmon"
  not_if      { ::File.exist?("#{node['kube-hops']['monitoring']['cert-crt']}") }
end

bash 'create-hopsmon-user-in-kubernetes' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  environment ({ 'HOME' => ::Dir.home(node['kube-hops']['user']) })
  retries 6
  retry_delay 30
  code <<-EOH
      kubectl config set-credentials #{node['kube-hops']['monitoring']['user']}  --client-certificate=#{node['kube-hops']['monitoring']['cert-crt']} --client-key=#{node['kube-hops']['monitoring']['cert-key']}
  EOH
  not_if "kubectl config view | grep #{node['kube-hops']['monitoring']['user']}", :environment => { 'HOME' => ::Dir.home(node['kube-hops']['user']) }
end

template "#{node['kube-hops']['conf_dir']}/kube-state-metrics.yaml" do
  source "kube-state-metrics.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply_kube_state_metrics' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['conf_dir']}/kube-state-metrics.yaml"
end

# run standalone cadvisor
# K8s 1.24 has removed the Docker plugin from cAdvisor and kubelet can no longer retrieve Docker container
# information such as image, pod, container labels, etc. through cAdvisor.
template "#{node['kube-hops']['conf_dir']}/cadvisor.yaml" do
  source "cadvisor.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

kube_hops_kubectl 'apply_cadvisor' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  url "#{node['kube-hops']['conf_dir']}/cadvisor.yaml"
end


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

  template "/home/#{node['kube-hops']['user']}/knative-serving-crds.yaml" do
    source "knative-serving-crds.yml.erb"
    owner node['kube-hops']['user']
    group node['kube-hops']['group']
  end

  template "/home/#{node['kube-hops']['user']}/knative-serving.yaml" do
    source "knative-serving.yml.erb"
    owner node['kube-hops']['user']
    group node['kube-hops']['group']
  end

  template "/home/#{node['kube-hops']['user']}/knative-istio.yaml" do
    source "knative-istio.yml.erb"
    owner node['kube-hops']['user']
    group node['kube-hops']['group']
  end

  kube_hops_kubectl 'apply-knative-serving-crds' do
    user node['kube-hops']['user']
    group node['kube-hops']['group']
    url "/home/#{node['kube-hops']['user']}/knative-serving-crds.yaml"
  end

  kube_hops_kubectl 'apply-knative-serving' do
    user node['kube-hops']['user']
    group node['kube-hops']['group']
    url "/home/#{node['kube-hops']['user']}/knative-serving.yaml"
  end

  kube_hops_kubectl 'apply-knative-istio-controller' do
    user node['kube-hops']['user']
    group node['kube-hops']['group']
    url "/home/#{node['kube-hops']['user']}/knative-istio.yaml"
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

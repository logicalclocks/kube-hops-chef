# Install KFServing and required tools

private_ip = my_private_ip()

# Helm

# The script detects arch/os and install helm accordingly
# Optional args:
# -v | --version: define specific version
# --no-sudo: install without sudo
template "/home/#{node['kube-hops']['user']}/istio.yml" do
  source "istio.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "/home/#{node['kube-hops']['user']}/istio-configure.yml" do
  source "istio-configure.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "/home/#{node['kube-hops']['user']}/knative-configure.yml" do
  source "knative-configure.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "/home/#{node['kube-hops']['user']}/certmgr.yml" do
  source "knative-configure.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

template "/home/#{node['kube-hops']['user']}/kfserving.yml" do
  source "kfserving.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end


bash 'install-helm' do
  user 'root'
  group 'root'
  code <<-EOH
    export PATH=$PATH:/usr/local/bin
    cd "#{Chef::Config['file_cache_path']}"
    curl -fsSL -o get_helm.sh #{node['kube-hops']['helm_script_url']}
    chmod 700 get_helm.sh
    ./get_helm.sh
    EOH
end

bash 'configure-helm' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
#  ignore_failure true
  code <<-EOH
    export PATH=$PATH:/usr/local/bin
    cd /home/#{node['kube-hops']['user']}
    chmod 400 .kube/config
    /usr/local/bin/helm repo add stable https://kubernetes-charts.storage.googleapis.com/
    /usr/local/bin/helm repo add jetstack https://charts.jetstack.io # cert-manager
    /usr/local/bin/helm repo update
    EOH
end

# Istio

# Download binaries
bash 'install-istio1' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    wget -nc #{node['kube-hops']['istio_url']}
    tar zxf istio-#{node['kube-hops']['istio_version']}-linux-amd64.tar.gz" 
    rm -f $HOME/istio
    ln -s $HOME/istio-#{node['kube-hops']['istio_version']} $HOME/istio
    EOH
  not_if { File.exist? "/home/#{node['kube-hops']['user'}/istioctl/bin" }
end

#    port: <%= node['kube-hops']['apiserver']['port'] %>
# Install CRDs
bash 'install-istio2' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    export PATH=$PATH:/usr/local/bin:$HOME/istio/bin
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config
    kubectl apply -f istio.yml
    EOH
end

bash 'install-istio3' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  cwd "home/" + node['kube-hops']['user']
  code <<-EOH
    export PATH=$PATH:/usr/local/bin:$HOME/istio/bin
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config

    helm template istio-#{node['kube-hops']['istio_version']}/manifests/charts/istio-operator/ \
      --kube-apiserver https://#{private_ip}:#{node['kube-hops']['apiserver']['port']} \
      --insecure-skip-tls-verify \
      --set hub=docker.io/istio \
      --set tag=#{node['kube-hops']['istio_version']} \
      --set operatorNamespace=istio-operator \
      --set watchedNamespaces=istio-system > kube-helm.yml
    kubectl apply -f kube-helm.yml
    EOH
end


# Install Istio Operator: without sidecar injection
# Notes: targetPort cannot be lower than 1024.
#        istioctl manifest apply not known, use install to apply manifests
bash 'configure-istio' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    chmod 400 $HOME/.kube/config
    export PATH=$PATH:/usr/local/bin:$HOME/istio/bin
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config
    cd /home/#{node['kube-hops']['user']}
    istioctl manifest install -f istio-configure.yml
    EOH
#  not_if ""
end

#
# Knative
#

# Install Knative Operator
# Note: Only knative serving is required. (Knative eventing can be installed independently)
bash 'install-knative' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    export PATH=$PATH:/usr/local/bin:$HOME/istio/bin
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config
    cd /home/#{node['kube-hops']['user']}
    ./istio/bin/kubectl apply -f #{node['kube-hops']['knative_chart']}
    EOH
#  not_if ""
end

# Install Knative Serving component
bash 'configure-knative' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    export PATH=$PATH:/usr/local/bin:$HOME/istio/bin
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config
    cd /home/#{node['kube-hops']['user']}
    ./istio/bin/kubectl apply -f knative-configure.yml
    EOH
end

#
# Cert-manager
#

# Install Cert-manager
bash 'install-cert-manager' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    cd /home/#{node['kube-hops']['user']}
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config
    export PATH=$PATH:/usr/local/bin:$HOME/istio/bin
    kubectl apply -f certmgr.yml
    EOH
end

bash 'helm-cert-manager' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    cd /home/#{node['kube-hops']['user']}
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config
    export PATH=$PATH:/usr/local/bin:$HOME/istio/bin

    helm install cert-manager jetstack/cert-manager --namespace cert-manager \
      --version v#{node['kube-hops']['certmgr_version']} --set installCRDs=true
    EOH
end

#
# KFServing
#

# Note: KFServing v0.4.0 not supported with Kubernetes 1.18
bash 'install-kfserving' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    export KUBECONFIG=$KUBECONFIG:/home/#{node['kube-hops']['user']}/.kube/config
    cd /home/#{node['kube-hops']['user']}
    kubectl apply -f kfserving.yaml
    EOH
end

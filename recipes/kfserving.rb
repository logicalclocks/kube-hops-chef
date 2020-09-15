# Install KFServing and required tools

# Helm

# The script detects arch/os and install helm accordingly
# Optional args:
# -v | --version: define specific version
# --no-sudo: install without sudo
template "/home/#{node['kube-hops']['user']}/kfserving.yml" do
  source "kfserving.yml.erb"
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
end

bash 'install-helm' do
  user 'root'
  group 'root'
  code <<-EOH
    curl #{node['kube-hops']['helm_script_url']} | bash
    EOH
#  not_if ""
end

bash 'configure-helm' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/
    helm repo add jetstack https://charts.jetstack.io # cert-manager
    helm repo update
    EOH
#  not_if ""
end

# Istio

# Download binaries
bash 'install-istio' do
  user 'root'
  group 'root'
  code <<-EOH
    curl -L #{node['kube-hops']['istio_script_url']} | ISTIO_VERSION=#{node['kube-hops']['istio_version']} sh -
    EOH
#  not_if ""
end

# Install CRDs
bash 'install-istio' do
  user ['kube-hops']['user']
  group ['kube-hops']['group']
  code <<-EOH
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Namespace
    metadata:
      name: istio-system
      labels:
        name: istio-system
    EOF

    helm template istio-#{node['kube-hops']['istio_version']}/manifests/charts/istio-operator/ \
      --set hub=docker.io/istio \
      --set tag=#{node['kube-hops']['istio_version']} \
      --set operatorNamespace=istio-operator \
      --set watchedNamespaces=istio-system | kubectl apply -f -
    EOH
#  not_if ""
end

# Install Istio Operator: without sidecar injection
# Notes: targetPort cannot be lower than 1024.
#        istioctl manifest apply not known, use install to apply manifests
bash 'configure-istio' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    cat <<EOF | istio-#{node['kube-hops']['istio_version']}/bin/istioctl manifest install -f -
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        global:
          proxy:
            autoInject: disabled
          useMCP: false
          # The third-party-jwt is not enabled on all k8s.
          # See: https://istio.io/docs/ops/best-practices/security/#configure-third-party-service-account-tokens
          jwtPolicy: first-party-jwt
      addonComponents:
        pilot:
          enabled: true
        prometheus:
          enabled: false
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
          - name: cluster-local-gateway
            enabled: true
            label:
              istio: cluster-local-gateway
              app: cluster-local-gateway
            k8s:
              service:
                type: ClusterIP
                ports:
                - port: 15020
                  name: status-port
                  targetPort: 15020
                - port: 80
                  name: http2
                  targetPort: 8080
                - port: 443
                  name: https
                  targetPort: 8443
    EOF
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
    kubectl apply -f https://github.com/knative/operator/releases/download/v0.17.0/operator.yaml
    EOH
#  not_if ""
end

# Install Knative Serving component
bash 'configure-knative' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Namespace
    metadata:
    name: knative-serving
    ---
    apiVersion: operator.knative.dev/v1alpha1
    kind: KnativeServing
    metadata:
      name: knative-serving
      namespace: knative-serving
    EOF
    EOH
#  not_if ""
end

#
# Cert-manager
#

# Install Cert-manager
bash 'install-cert-manager' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Namespace
    metadata:
      name: cert-manager
      labels:
        name: cert-manager
    EOF

    helm install \
      cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --version v1.0.1 \
      --set installCRDs=true
    EOH
#  not_if ""
end

#
# KFServing
#

# Note: KFServing v0.4.0 not supported with Kubernetes 1.18
bash 'install-kfserving' do
  user node['kube-hops']['user']
  group node['kube-hops']['group']
  code <<-EOH
    kubectl apply -f kfserving.yaml
    EOH
#  not_if ""
end

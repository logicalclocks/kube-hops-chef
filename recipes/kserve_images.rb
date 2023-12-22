docker_registry = "#{consul_helper.get_service_fqdn("registry")}:#{node['hops']['docker']['registry']['port']}"
kserve_images = "#{Chef::Config['file_cache_path']}/kserve-v#{node['kube-hops']['kserve']['version']}.tgz"
remote_file kserve_images do
  source node['kube-hops']['kserve']['img_tar_url']
  owner node['kube-hops']['user']
  group node['kube-hops']['group']
  mode "0644"
end

bash "load" do
  user 'root'
  group 'root'
  code <<-EOH
    docker load < #{kserve_images}
  EOH
end

knative_image_names = ["serving/cmd/controller", "serving/cmd/autoscaler", "serving/cmd/domain-mapping", "serving/cmd/activator", "serving/cmd/domain-mapping-webhook", "serving/cmd/queue", "serving/cmd/webhook", "net-istio/cmd/webhook", "net-istio/cmd/controller"]
bash "push_knative_images_to_local_registry" do
  user 'root'
  group 'root'
  code <<-EOH
    KNATIVE_IMAGES=(#{knative_image_names.join(' ')})
    for NAME in "${KNATIVE_IMAGES[@]}"; do
      #append the knative.dev prefix
      NAME=knative.dev/$NAME
      IMAGE=#{docker_registry}/$NAME:#{node['kube-hops']['knative']['version']}
      docker tag $NAME:#{node['kube-hops']['knative']['version']} $IMAGE
      docker push $IMAGE
      docker rmi $NAME:#{node['kube-hops']['knative']['version']}
    done
  EOH
end

kserve_image_names = ["kserve/kserve-controller", "kserve/agent", "kserve/storage-initializer", "kserve/alibi-explainer", "kserve/art-explainer"]
bash "push_kserve_images_to_local_registry" do
  user 'root'
  group 'root'
  code <<-EOH
    KSERVE_IMAGES=(#{kserve_image_names.join(' ')})
    for NAME in "${KSERVE_IMAGES[@]}"; do
      IMAGE=#{docker_registry}/$NAME:#{node['kube-hops']['kserve']['version']}
      docker tag $NAME:#{node['kube-hops']['kserve']['version']} $IMAGE
      docker push $IMAGE
      docker rmi $NAME:#{node['kube-hops']['kserve']['version']}
    done
  EOH
end

certmanager_image_names = ["cert-manager-controller", "cert-manager-webhook", "cert-manager-cainjector"]
bash "push_certmanager_images_to_local_registry" do
  user 'root'
  group 'root'
  code <<-EOH
    CERTMANAGER_IMAGES=(#{certmanager_image_names.join(' ')})
    for NAME in "${CERTMANAGER_IMAGES[@]}"; do
      #append the quay.io/jetstack prefix
      NAME=quay.io/jetstack/$NAME
      IMAGE=#{docker_registry}/$NAME:#{node['kube-hops']['cert-manager']['version']}
      docker tag $NAME:#{node['kube-hops']['cert-manager']['version']} $IMAGE
      docker push $IMAGE
      docker rmi $NAME:#{node['kube-hops']['cert-manager']['version']}
    done
  EOH
end

istio_image_names = ["istio/proxyv2", "istio/pilot"]
bash "push_istio_images_to_local_registry" do
  user 'root'
  group 'root'
  code <<-EOH
    ISTIO_IMAGES=(#{istio_image_names.join(' ')})
    for NAME in "${ISTIO_IMAGES[@]}"; do
      IMAGE=#{docker_registry}/$NAME:#{node['kube-hops']['istio']['version'] }
      docker tag $NAME:#{node['kube-hops']['istio']['version'] } $IMAGE
      docker push $IMAGE
      docker rmi $NAME:#{node['kube-hops']['istio']['version'] }
    done
  EOH
end

tensorflow_images = ["tensorflow/serving:#{node['kube-hops']['kserve']['tensorflow']['version']}", "tensorflow/serving:#{node['kube-hops']['kserve']['tensorflow']['version']}-gpu"]
bash "push_tensorflow_images_to_local_registry" do
  user 'root'
  group 'root'
  code <<-EOH
    TENSORFLOW_IMAGES=(#{tensorflow_images.join(' ')})
    for NAME in "${TENSORFLOW_IMAGES[@]}"; do
      IMAGE=#{docker_registry}/$NAME
      docker tag $NAME $IMAGE
      docker push $IMAGE
      docker rmi $NAME
    done
  EOH
end

bash "push_kubebuilder-kube-rbac-proxy_image_to_local_registry" do
  user 'root'
  group 'root'
  code <<-EOH
    IMAGE=kubebuilder/kube-rbac-proxy:v0.13.1
    docker tag $IMAGE  #{docker_registry}/$IMAGE
    docker push #{docker_registry}/$IMAGE
    docker rmi $IMAGE
  EOH
end

action :apply do
  Chef::Log.info "Applying #{new_resource.name}"
  bash "apply-yaml" do
    user new_resource.user
    group new_resource.group
    environment ({ 'HOME' => ::Dir.home(new_resource.user) })
    code <<-EOH
      kubectl apply -f #{new_resource.url} #{new_resource.flags}
    EOH
  end
end

action :taint do 
  bash "apply-taint" do
    user new_resource.user
    group new_resource.group
    environment ({ 'HOME' => ::Dir.home(new_resource.user) })
    code <<-EOH
      kubectl taint nodes #{new_resource.k8s_node} #{new_resource.name} --overwrite
    EOH
  end
end

action :label do
  bash "apply-label" do
    user new_resource.user
    group new_resource.group
    environment ({ 'HOME' => ::Dir.home(new_resource.user) })
    code <<-EOH
      kubectl label nodes #{new_resource.k8s_node} #{new_resource.name} --overwrite
    EOH
  end
end

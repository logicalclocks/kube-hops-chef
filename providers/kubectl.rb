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

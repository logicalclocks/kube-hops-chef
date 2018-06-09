action :generate do
  bash 'gen-rsa-key' do
    user node['kube-hops']['user']
    group node['kube-hops']['group']
    cwd new_resource.path
    code <<-EOH
      openssl genrsa -out #{new_resource.name}.key 2048
      openssl rsa -in #{new_resource.name}.key -pubout -out #{new_resource.name}.pub
    EOH
  end
end

action :generate do

  # Generate and sign the certificate
  kube_hops_certs new_resource.name do
    path      new_resource.path
    subject   new_resource.subject
    not_if { ::File.exist?("#{new_resource.path}/#{new_resource.name}.crt") }
  end

  ca_cert_data = ""
  client_cert_data = ""
  client_key_data = ""

  # Read the content of the files
  ruby_block 'read_crypto' do
    block do
      require 'base64'

      ca_cert_data = ::File.read("#{node['kube-hops']['pki']['dir']}/ca.crt")
      ca_cert_data = ::Base64.strict_encode64(ca_cert_data)

      client_cert_data = ::File.read("#{new_resource.path}/#{new_resource.name}.crt")
      client_cert_data = ::Base64.strict_encode64(client_cert_data)

      client_key_data = ::File.read("#{new_resource.path}/#{new_resource.name}.key")
      client_key_data = ::Base64.strict_encode64(client_key_data)
    end
  end

  # Template file
  template "#{node['kube-hops']['conf_dir']}/#{new_resource.name}.conf" do
    source "component-conf.erb"
    owner "root"
    group "root"
    mode "600"
     variables( lazy {
      h = {}
      h['master_ip'] = new_resource.master_ip
      h['ca_cert_data'] = ca_cert_data
      h['client_cert_data'] = client_cert_data
      h['client_key_data'] = client_key_data
      h['component'] = new_resource.component
      h
    })
  end
end

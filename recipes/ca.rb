kube_intermediate_ca_dir = "#{node['certs']['dir']}/kube"
kube_hopsworkscerts = "#{kube_intermediate_ca_dir}/hopsworks"

# If the user has redefined the the Hopsworks user
# then overwrite the ca_api_user and ca_api_group
if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('user')
    node.override['kube-hops']['pki']['ca_api_user'] = node['hopsworks']['user']
  end
  if node['hopsworks'].attribute?('group')
    node.override['kube-hops']['pki']['ca_api_group'] = node['hopsworks']['group']
  end
end

# Create directories
directory kube_intermediate_ca_dir do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  mode "700"
end

# Generate and sign Hopsworks certificate
# If you don't use the same password for both the key and the keystore
# The Kubernetes client doesn't work.
directory kube_hopsworkscerts do
  user  node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
end

bash 'generate-and-sign-key' do
  user "root"
  group "root"
  cwd kube_hopsworkscerts
  code <<-EOH
    set -e
    openssl genrsa -passout pass:#{node['kube-hops']['hopsworks_cert_pwd']} -out hopsworks.key.pem #{node['kube-hops']['pki']['keysize']}
    chmod 400 hopsworks.key.pem
    chown #{node['kube-hops']['pki']['ca_api_user']} hopsworks.key.pem
    openssl req -subj "/CN=hopsworks" -passin pass:#{node['kube-hops']['hopsworks_cert_pwd']} -passout pass:#{node['kube-hops']['hopsworks_cert_pwd']} -key hopsworks.key.pem -new -sha256 -out hopsworks.csr.pem
  EOH
  not_if { ::File.exist?("#{kube_hopsworkscerts}/hopsworks.cert.pem") }
end

kagent_pki "sign-certificate" do
  ca_path "hopsworks-ca/v2/certificate/kube"
  csr_file "#{kube_hopsworkscerts}/hopsworks.csr.pem"
  output_dir kube_hopsworkscerts
  action :sign_csr
  not_if { ::File.exist?("#{kube_hopsworkscerts}/hopsworks.cert.pem") }
end

bash "fix-certificate-permissions" do
  user "root"
  group "root"
  cwd kube_hopsworkscerts
  code <<-EOH
    mv signed_certificate.pem hopsworks.cert.pem
    chmod 400 hopsworks.cert.pem
    chown #{node['kube-hops']['pki']['ca_api_user']} hopsworks.cert.pem
    mv intermediate_ca.pem kube-ca.cert.pem
    chmod 755 kube-ca.cert.pem
    chown #{node['kube-hops']['pki']['ca_api_user']} kube-ca.cert.pem
  EOH
  not_if { ::File.exist?("#{kube_hopsworkscerts}/hopsworks.cert.pem") }
end

bash "move kube-ca pem file" do
  user 'root'
  group 'root'
  code <<-EOH
    mv #{kube_intermediate_ca_dir}/certs/kube-ca.cert.pem #{kube_hopsworkscerts}/kube-ca.cert.pem
  EOH
  only_if conda_helpers.is_upgrade
  not_if { ::File.exist?("#{kube_hopsworkscerts}/kube-ca.cert.pem") }
end

bash 'generate-key/trustStore' do
  user "root"
  group "root"
  cwd kube_hopsworkscerts
  code <<-EOH
    set -e
    openssl pkcs12 -export -in hopsworks.cert.pem -inkey hopsworks.key.pem -out cert_and_key.p12 -name hopsworks -CAfile kube-ca.cert.pem -caname root -password pass:#{node['kube-hops']['hopsworks_cert_pwd']}
    keytool -importkeystore -destkeystore hopsworks__kstore.jks -srckeystore cert_and_key.p12 -srcstoretype PKCS12 -alias hopsworks -srcstorepass #{node['kube-hops']['hopsworks_cert_pwd']} -deststorepass #{node['kube-hops']['hopsworks_cert_pwd']} -destkeypass #{node['kube-hops']['hopsworks_cert_pwd']}
    keytool -import -noprompt -trustcacerts -alias CARoot -file kube-ca.cert.pem -keystore hopsworks__tstore.jks -srcstorepass #{node['kube-hops']['hopsworks_cert_pwd']} -deststorepass #{node['kube-hops']['hopsworks_cert_pwd']} -destkeypass #{node['kube-hops']['hopsworks_cert_pwd']}

    chmod 400 hopsworks__tstore.jks
    chmod 400 hopsworks__kstore.jks
    chown #{node['kube-hops']['pki']['ca_api_user']} hopsworks__tstore.jks
    chown #{node['kube-hops']['pki']['ca_api_user']} hopsworks__kstore.jks
    rm cert_and_key.p12
  EOH
  not_if { ::File.exist?("#{kube_hopsworkscerts}/hopsworks__kstore.jks") }
end

kube_intermediate_ca_dir = "#{node['certs']['dir']}/kube"
kube_private = "#{kube_intermediate_ca_dir}/private"
kube_csr = "#{kube_intermediate_ca_dir}/csr"
kube_certs = "#{kube_intermediate_ca_dir}/certs"
kube_newcerts = "#{kube_intermediate_ca_dir}/newcerts"
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

directory kube_private do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  mode "700"
end

directory kube_csr do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  mode "700"
end

directory kube_certs do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  mode "700"
end

directory kube_newcerts do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  mode "700"
end

# Template CA configuration file
master_cluster_ip = private_recipe_ip('kube-hops', 'master')

# ATM we support only single master.
master_hostname = private_recipe_hostnames('kube-hops', 'master')[0]
template "#{kube_intermediate_ca_dir}/kube-ca.cnf" do
  source "kube-ca.cnf.erb"
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  variables ({
    'master_cluster_ip': master_cluster_ip,
    'master_hostname': master_hostname
  })
end

file "#{kube_intermediate_ca_dir}/serial" do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  content "1000\n"
  action :create_if_missing
end

file "#{kube_intermediate_ca_dir}/crlnumber" do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  content "1000\n"
  action :create_if_missing
end

file "#{kube_intermediate_ca_dir}/index.txt" do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  action :create_if_missing
end

file "#{kube_intermediate_ca_dir}/index.txt.attr" do
  owner node['kube-hops']['pki']['ca_api_user']
  group node['kube-hops']['pki']['ca_api_group']
  action :create_if_missing
end

bash 'create-and-sign-key' do
  user        'root'
  group       'root'
  environment ({"KEYPW" => node['kube-hops']['pki']['ca_keypw'],
               "MASTERKEYPW" => node['kube-hops']['pki']['rootca_keypw']})
  cwd         kube_intermediate_ca_dir
  code <<-EOH
    set -e

    # Generate key
    [ -f #{kube_private}/kube-ca.key.pem ] || openssl genrsa -aes256 -out #{kube_private}/kube-ca.key.pem -passout pass:${KEYPW} 4096

    chown #{node['kube-hops']['pki']['ca_api_user']}:#{node['kube-hops']['pki']['ca_api_group']} #{kube_private}/kube-ca.key.pem
	  chmod 440 #{kube_private}/kube-ca.key.pem

    # Generate CSR
    [ -f #{kube_csr}/kube-ca.csr.pem ] || openssl req -new -sha256 -subj "/C=SE/ST=Sweden/L=Stockholm/O=LogicalClocks/CN=KubeHopsIntermediateCA" \
      -key #{kube_private}/kube-ca.key.pem -passin pass:${KEYPW} -passout pass:${KEYPW} -out #{kube_csr}/kube-ca.csr.pem

    # Sign CSR
    [ -f #{kube_certs}/kube-ca.cert.pem ] || openssl ca -batch -config ../openssl-ca.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 -passin pass:${MASTERKEYPW} -in #{kube_csr}/kube-ca.csr.pem -out #{kube_certs}/kube-ca.cert.pem

	  chmod 444 #{kube_certs}/kube-ca.cert.pem

    # TODO(Fabio) generate the certificate chain

    # Verify
	  openssl verify -CAfile #{node['certs']['dir']}/certs/ca.cert.pem #{kube_certs}/kube-ca.cert.pem
  EOH
  not_if { ::File.exist?("#{kube_certs}/kube-ca.cert.pem") }
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
    openssl ca -batch -config ../kube-ca.cnf -passin pass:#{node['kube-hops']['pki']['ca_keypw']} -extensions v3_ext -days 365 -notext -md sha256 -in hopsworks.csr.pem -out hopsworks.cert.pem
    chmod 400 hopsworks.cert.pem
    chown #{node['kube-hops']['pki']['ca_api_user']} hopsworks.cert.pem
  EOH
  not_if { ::File.exist?("#{kube_hopsworkscerts}/hopsworks.cert.pem") }
end

bash 'generate-key/trustStore' do
  user "root"
  group "root"
  cwd kube_hopsworkscerts
  code <<-EOH
    set -e
    openssl pkcs12 -export -in hopsworks.cert.pem -inkey hopsworks.key.pem -out cert_and_key.p12 -name hopsworks -CAfile ../certs/kube-ca.cert.pem -caname root -password pass:#{node['kube-hops']['hopsworks_cert_pwd']}
    keytool -importkeystore -destkeystore hopsworks__kstore.jks -srckeystore cert_and_key.p12 -srcstoretype PKCS12 -alias hopsworks -srcstorepass #{node['kube-hops']['hopsworks_cert_pwd']} -deststorepass #{node['kube-hops']['hopsworks_cert_pwd']} -destkeypass #{node['kube-hops']['hopsworks_cert_pwd']}
    keytool -import -noprompt -trustcacerts -alias CARoot -file ../certs/kube-ca.cert.pem -keystore hopsworks__tstore.jks -srcstorepass #{node['kube-hops']['hopsworks_cert_pwd']} -deststorepass #{node['kube-hops']['hopsworks_cert_pwd']} -destkeypass #{node['kube-hops']['hopsworks_cert_pwd']}

    chmod 400 hopsworks__tstore.jks
    chmod 400 hopsworks__kstore.jks
    chown #{node['kube-hops']['pki']['ca_api_user']} hopsworks__tstore.jks
    chown #{node['kube-hops']['pki']['ca_api_user']} hopsworks__kstore.jks
    rm cert_and_key.p12
  EOH
  not_if { ::File.exist?("#{kube_hopsworkscerts}/hopsworks__kstore.jks") }
end

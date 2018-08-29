# Set configuration parameters in the settings table
# Template the file into flyway dir and let flyway migrate to take care of this

domains_dir = "/srv/hops/domains"
domain_name = "domain1"

if node.attribute?('hopsworks')
  if node['hopsworks'].attribute?('domain_name')
    domain_name = node['hopsworks']['domain_name']
  end

  if node['hopsworks'].attribute?('domains_dir')
    domains_dir = node['hopsworks']['domains_dir']
  end
end
theDomain="#{domains_dir}/#{domain_name}"

glassfish_user = "glassfish"
if node.attribute?('glassfish')
  if node['glassfish'].attribute?('user')
    glassfish_user = node['glassfish']['user']
  end
end

master_cluster_ip = private_recipe_ip('kube-hops', 'master')

template "#{theDomain}/flyway/sql/R__kube-settings.sql" do
    source "settings.sql.erb"
    owner glassfish_user
    mode 0750
    variables({
      'master_ip': master_cluster_ip
    })
end

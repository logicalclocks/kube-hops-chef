actions :generate, :fetch_cert

attribute :name, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String, :required => true
attribute :subject, :kind_of => String, :required => true
attribute :master_ip, :kind_of => String, :required => true
attribute :component, :kind_of => String, :required => true

default_action :generate

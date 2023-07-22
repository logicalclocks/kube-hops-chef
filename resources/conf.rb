actions :generate, :fetch_cert

attribute :name, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String
attribute :subject, :kind_of => String
attribute :master_ip, :kind_of => String
attribute :component, :kind_of => String

default_action :generate

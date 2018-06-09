actions :generate, :fetch_cert

attribute :name, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String, :required => true
attribute :subject, :kind_of => String, :required => true
attribute :owner, :kind_of => String, :required => true
attribute :group, :kind_of => String, :required => true
attribute :ca_path, :kind_of => String, :required => false
attribute :ca_name, :kind_of => String, :required => false
attribute :self_signed, :kind_of => [TrueClass, FalseClass], default: false

default_action :generate

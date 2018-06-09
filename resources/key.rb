actions :generate

attribute :name, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String, :required => true

default_action :generate

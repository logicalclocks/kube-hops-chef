actions :apply, :taint, :label

attribute :name, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => String, :required => true
attribute :group, :kind_of => String, :required => true
attribute :url, :kind_of => String, :required => true
attribute :flags, :kind_of => String, :required => false
attribute :k8s_node, :kind_of => String, :required => false

default_action :apply

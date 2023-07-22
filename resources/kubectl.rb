actions :apply, :taint, :label

attribute :name, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => String
attribute :group, :kind_of => String
attribute :url, :kind_of => String
attribute :flags, :kind_of => String
attribute :k8s_node, :kind_of => String

default_action :apply

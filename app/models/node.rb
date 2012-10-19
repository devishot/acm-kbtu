class Node
  include Mongoid::Document
  
  field :name, type: String
  field :path, type: String
  field :order, type: Integer

  field :count_pages_in_node, type: Integer, default: 0

  has_many :pages
end

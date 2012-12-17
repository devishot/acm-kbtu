class Node
  include Mongoid::Document
  
  field :name, type: String
  field :path, type: String
  field :order, type: Integer, default: Node.count + 1
  field :count_pages_in_node, type: Integer, default: 0

  has_many :pages

end

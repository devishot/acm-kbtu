class Node
  include Mongoid::Document
  
  @@count_all_nodes = 0

  def self.count
    @@count_all_nodes += 1
    @@count_all_nodes
  end

  field :name, type: String
  field :path, type: String
  field :order, type: Integer

  field :count_pages_in_node, type: Integer, default: 0

  has_many :pages
end

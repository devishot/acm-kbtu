class Node
  include Mongoid::Document
  field :name, type: String
  field :path, type: String
  field :order, type: Integer

  has_many :pages
end

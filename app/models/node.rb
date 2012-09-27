class Node
  include Mongoid::Document
  field :name, type: String
  field :path, type: String
  field :order, type: Integer

  embeds_many :page
end

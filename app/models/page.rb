class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text_title, type: String
  field :text_body, type: String
  field :path, type: Integer, default: 1000 + Page.count
  field :order, type: Integer
  field :old_node, type: String

  belongs_to :node
  belongs_to :user
  
end

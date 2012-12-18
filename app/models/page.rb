class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text_title, type: String
  field :text_body, type: String
  field :path, type: String, default: (Page.exists? ? (Page.last.path.to_i() + 1).to_s() : '1000')
  field :order, type: Integer
  field :old_node

  belongs_to :node
  belongs_to :user
  
end

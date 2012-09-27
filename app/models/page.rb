class Page
  include Mongoid::Document
  field :text_title, type: String
  field :text_body, type: String
  field :author, type: String
  field :parent, type: String
  field :path, type: String
  field :order, type: Integer

  field :old_node, type: String
  field :old_path, type: String

  embedded_in :node
end

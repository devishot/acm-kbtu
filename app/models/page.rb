class Page
  include Mongoid::Document
  field :text_title, type: String
  field :text_body, type: String
  field :author, type: String
  field :parent, type: String
  field :path, type: String
  field :order, type: Integer
end

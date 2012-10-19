class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  @@count_all_pages = 2537

  def self.count
    @@count_all_pages += 1
  end

  field :text_title, type: String
  field :text_body, type: String
  field :author, type: String
  field :parent, type: String
  field :path, type: Integer
  field :order, type: Integer

  field :old_node, type: String

  belongs_to :node
  belongs_to :user
end

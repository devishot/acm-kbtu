class Page
  @@pages_count = 2537

  def self.how
    @@pages_count
  end

  def self.count
    @@pages_count += 1
  end

  include Mongoid::Document
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

class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text_title, type: String
  field :text_body, type: String
  field :path, type: String
  field :order, type: Integer
  field :old_node

  belongs_to :node
  belongs_to :user

  before_create :set_path

  def set_path
    node_pages = Page.where(node: self.node)
    self.path = node_pages.blank? ? '1' : (node_pages.sort!{|t1,t2| t2.path.to_i <=> t1.path.to_i}[0].path.to_i + 1).to_s()
  end
  
end

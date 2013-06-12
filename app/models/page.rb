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
   self.path = (Page.where(node: self.node).count + 1).to_s()
  end
  
end

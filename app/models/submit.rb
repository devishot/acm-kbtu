class Submit
	include Mongoid::Document
	include Mongoid::Timestamps
  field :order, type: Integer
	field :file_sourcecode_path, type: String
	field :status, type: Hash, default: {}

	belongs_to :problem
	belongs_to :participant


  after_create :set_order

  def set_order
    self.order = self.problem.submits.size + 1
  end

end

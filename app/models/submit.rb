class Submit
	include Mongoid::Document
	include Mongoid::Timestamps
  field :order,        type: Integer
	field :sourcecode,   type: String
	field :status,       type: Hash, default: {}
  field :folder,       type: String

	belongs_to :problem
	belongs_to :participant


  before_create :set_order, :set_folder

  def set_order
    self.order = self.problem.submits.size + 1
  end

  def set_folder
    self.folder = self.problem.contest.contest_dir+"/submits/participant #{self.participant.path}"
  end

end

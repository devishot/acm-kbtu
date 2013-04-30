class Submit
	include Mongoid::Document
	include Mongoid::Timestamps
  field :order,        type: Integer
	field :sourcecode,   type: String
	field :status,       type: Hash,      default: {}
  field :folder,       type: String
  field :hidden,       type: Boolean,   default: false 

	belongs_to :problem
	belongs_to :participant


  before_create :set_order, :set_folder

  def set_order
    if self.hidden==true
      self.order = 0
    else
      self.order = self.problem.submits.where(participant: self.participant).size + 1
    end
  end

  def set_folder
    if self.hidden == true 
      self.folder = "#{Rails.root}/judge-files/check-system/tmp/contest #{self.problem.contest.path}(hidden)"
      FileUtils.mkdir_p self.folder
    else
      self.folder = self.problem.contest.contest_dir+"/submits/participant #{self.participant.path}"
    end
  end

end


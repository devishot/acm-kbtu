class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  field :global_path, type: String
  field :order, type: Integer
  field :tests_path, type: String
  field :statement, type: Hash #{:text => params[:text], :inputs => [], :outputs => []}

  belongs_to :contest
  has_many :submits


  before_save :set_global_path
  
  def set_global_path
    return if self.global_path != nil || self.contest.problems_type == 0
    self.global_path = (Problem.exists? ? (Problem.last.global_path.to_i + 1).to_s : '1')
  end
end

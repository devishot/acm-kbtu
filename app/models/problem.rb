class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  field :global_path, type: String
  field :order, type: Integer
  field :tests_path, type: String

  belongs_to :contest
  has_many :submits


  before_save :set_global_path
  
  def set_global_path
    return if self.global_path != nil

    if Problem.exists?
      path = ( Problem.last.global_path.to_i() + 1 ).to_s()
    else
      path = '1'
    end    
    self.global_path = path
  end
end

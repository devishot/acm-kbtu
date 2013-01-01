class Participant
  include Mongoid::Document

  field :path, type: String
  belongs_to :user
  belongs_to :contest
  has_many :submits


  before_save :set_path
  
  def set_path
    return if self.path != nil

    if ((self.contest).participants).exists?
      path = ( ((self.contest).participants).last.path.to_i() + 1 ).to_s()
    else
      path = '1'
    end    
    self.path = path
  end
end

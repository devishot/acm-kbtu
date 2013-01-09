class Contest
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :name, type: String
  field :description, type: String
  field :path, type: String
  field :time_start, type: DateTime
  field :time_finish, type: DateTime
  field :problems_count, type: Integer
  field :problems_type, type: Integer

  has_many :problems
  has_many :participants
  belongs_to :user

  before_save :set_path
  
  def set_path
    return if self.path != nil

    if Contest.exists?
      path = ( Contest.last.path.to_i() + 1 ).to_s()
    else
      path = '1'
    end    
    self.path = path
  end

  def isover?
    return 1 if Time.now < time_start 
    return 2 if Time.now >= time_start  && Time.now <= time_finish
    return 3 if Time.now > time_finish
  end

end

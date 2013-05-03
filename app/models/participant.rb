class Participant
  include Mongoid::Document

  field :path, type: String
  belongs_to :user
  belongs_to :contest
  has_many :submits
  has_many :messages
  
# for standings
  field :penalty, type: Integer, default: 0
  field :penalties, type: Array, default: []
  field :a, type: Array, default: []
  field :point, type: Integer, default: 0

  before_create :set_path, :create_folder, :set_standings
  before_destroy :clear
  
  def set_path
    participants = self.contest.participants
    self.path = (participants.exists?) ? 
        ( participants.all.sort_by{|i| i.path.to_i}.last.path.to_i + 1 ).to_s : '1'
  end

  def create_folder
    FileUtils.mkdir_p self.participant_dir
  end     

  def set_standings
    contest.problems_count.times do |i|
      a[i + 1] = 0
      penalties[i + 1] = 0
    end
  end

  def clear
    FileUtils.rm_rf self.participant_dir    
    self.user.participants.delete(self)    
    self.contest.participants.delete(self)
    self.submits.destroy_all
  end

  def participant_dir
    self.contest.contest_dir+"/participants/#{self.path}"
  end

  def summarize
    self.point = 0
    self.penalty = 0    
    for i in 1..self.contest.problems_count
      self.penalty += self.penalties[i] if self.a[i]> 0
      self.point += 1 if self.a[i] > 0
    end
    self.save!
  end

end

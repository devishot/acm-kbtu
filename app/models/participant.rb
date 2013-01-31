class Participant
  include Mongoid::Document

  field :path, type: String
  belongs_to :user
  belongs_to :contest
  has_many :submits
  has_many :messages
  
# for standings
  field :penalty, type: Integer, default: 0
  field :penalties, type: Array
  field :a, type: Array
  field :point, type: Integer, default: 0

  before_save :set_path, :set_standings
  
  def summarize
    for i in 1..self.contest.problems_count
      self.penalties[i] = (self.a[i] * 30).abs
      self.penalty += self.penalties[i].to_i if self.a[i] > 0
      self.point += 1 if self.a[i] > 0
    end

  end

  def set_path
    return if self.path != nil
    participants = self.contest.participants
    self.path = (participants.exists?) ? (participants.last.path.to_i()+1).to_s() : '1'
  end

  before_destroy do |participant|
    participant_folder = 
      "#{Rails.root}/judge-files/contests/#{participant.contest.path}/participants/#{participant.path}"    
    participant.user.participants.delete(participant)    
    participant.contest.participants.delete(participant)
    participant.submits.destroy_all

    FileUtils.rm_rf participant_folder
  end

  def set_standings
    self.penalties = self.penalties.to_a
    self.a = self.a.to_a

    for i in 1..self.contest.problems_count
      self.a.insert(i, 0)
      self.penalties.insert(i, 0)
    end

    self.a[1] = 2
    self.a[2] = -1

  end

end

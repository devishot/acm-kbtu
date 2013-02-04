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

  before_create :set_path, :set_standings
  
  def summarize
    self.point = 0
    self.penalty = 0    
    for i in 1..self.contest.problems_count
      self.penalty += self.penalties[i].to_i if self.a[i].to_i > 0
      self.point += 1 if self.a[i] > 0
    end
    self.save!
  end

  def set_path
    return if path != nil
    participants = contest.participants
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
    contest.problems_count.times do |i|
      a[i + 1] = 0
      penalties[i + 1] = 0
    end
  end

end

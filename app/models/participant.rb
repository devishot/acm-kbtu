class Participant
  include Mongoid::Document

  field :path, type: String
  belongs_to :user
  belongs_to :contest
  has_many :submits


  before_save :set_path
  
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
end

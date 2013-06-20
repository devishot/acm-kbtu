class Participant
  include Mongoid::Document

  field :path, type: String
  field :confirmed, type: Boolean, default: false

  belongs_to :user
  belongs_to :contest
  has_many :submits
  has_many :messages
  
# for standings
  field :penalty,   type: Integer,  default: 0
  field :penalties, type: Array,    default: []
  field :a,         type: Array,    default: []
  field :point,     type: Integer,  default: 0

  before_create   :set_path, :set_standings
  before_destroy  :clear
  
  def set_path
    participants = self.contest.participants
    self.path = (participants.exists?) ? 
        ( participants.all.sort_by{|i| i.path.to_i}.last.path.to_i + 1 ).to_s : '1'
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
    self.point    = 0
    self.penalty  = 0
    for i in 1..self.contest.problems_count
      next if self.a[i] <= 0

      if self.contest.type==0 #ACM
        self.penalty  += self.penalties[i] 
        self.point    += 1

      elsif self.contest.type==1 #IOI

        self.point += self.a[i]
      end
    end
  end

  def attempt(problem_number)#for standings
    i = problem_number
    if self.contest.type==1 #IOI
      return self.a[i]
      
    elsif self.contest.type==0 #ACM
      if self.a[i] == 1
        return "+"
      elsif self.a[i] > 0      
        return "+"+(self.a[i]-1).to_s 
      elsif self.a[i] < 0
        return self.a[i].to_s
      end

    end
  end

  def attempts(problem_id)#for limit
    return self.contest.submit_limit - self.submits.where(problem: problem_id).where('status.status' => 'OK').count
  end

end

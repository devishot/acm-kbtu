class Participant
  include Mongoid::Document

  belongs_to :user
  belongs_to :contest
  has_many :submits
end

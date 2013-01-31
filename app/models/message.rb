class Message
  include Mongoid::Document
	# include Mongoid::Timestamps

	# field :theme, type: String
  field :text, type: String

  belongs_to :participant
end

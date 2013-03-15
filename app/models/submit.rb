class Submit
	include Mongoid::Document
	include Mongoid::Timestamps
	field :file_sourcecode_path, type: String
	field :status, type: Hash, default: {}

	belongs_to :problem
	belongs_to :participant
end

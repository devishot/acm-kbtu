class Submit
  include Mongoid::Document
  field :solution_file, type: String
  field :status, type: String
  field :status_full, type: String

  belongs_to :problem
  belongs_to :user
end

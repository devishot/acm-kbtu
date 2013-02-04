require 'zip/zipfilesystem'

class Contest
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :title, type: String
  field :description, type: String
  field :path, type: String
  field :time_start, type: DateTime
  field :duration, type: Integer, :default => 300#minutes
  field :type, type: Integer, :default => 0 #"ACM", "IOI"
  field :problems_count, type: Integer, :default => 1
  field :problems_upload, type: Integer, :default => 0 #"one_archive", "every_problem"

  belongs_to :user
  has_many :problems
  has_many :participants

  before_save :set_path
  before_destroy :clear
  
  def set_path
    return if self.path != nil
    self.path = (Contest.exists?) ? ( Contest.last.path.to_i + 1 ).to_s : '1'
  end

  def clear
    #destroy all problems and submits
    self.problems.each do |problem|
      problem.submits.destroy_all
      problem.destroy
    end
    #destroy all participants
    self.participants.destroy_all
    #delete contest folder
    FileUtils.rm_rf self.contest_dir
  end

  def contest_dir
    "#{Rails.root}/judge-files/contests/#{self.path}"
  end

  def started?
    (self.time_start.nil? || Time.now < self.time_start) ? false : true
  end

  def over?
    (self.started? && Time.now > self.time_start+self.duration.minutes) ? true : false
  end

  def unpack(archive)
    #create folder if not exist
    FileUtils.mkdir_p self.contest_dir
    #write archive_file(.zip) in contest_dir
    File.open(Rails.root.join(self.contest_dir, archive.original_filename), 'w') do |file|
      file.write(archive.read.force_encoding('utf-8'))
    end
    #exctract files(folders) from archive_file(.zip)
    Zip::ZipFile.open(self.contest_dir+"/#{archive.original_filename}"){ |zip_file|
      zip_file.each { |f|
        f_path=File.join(self.contest_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }
    #delete archive_file(.zip)
    FileUtils.remove_file(self.contest_dir+"/#{archive.original_filename}")
  end

  def problems_create(statement=nil)
    for i in 1..self.problems_count
      problem = Problem.new({
        :contest => self,
        :order => i,
        :tests_path => (self.problems_upload==1) ? nil : self.contest_dir+"/problems/#{i}/tests",
        :statement => (self.problems_upload==1) ? 
                      {:title=>'', :text => '', :inputs => [], :outputs => []} 
                      : 
                      {:link => self.put_statement(statement)}
      });
      problem.save
      self.problems << problem
    end
  end

  def put_statement(ufile)
    return if ufile.nil?
    statement_dir = self.contest_dir+'/statement'
    FileUtils.mkdir_p statement_dir
    File.open(Rails.root.join(statement_dir, ufile.original_filename), 'w') do |file|
      file.write(ufile.read.force_encoding('utf-8'))
    end
    return statement_dir+"/#{ufile.original_filename}"
  end
end

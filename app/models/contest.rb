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
  field :problems_count, type: Integer, :default => 0 #problems[0] <- it is template for other problem
# field :statement_link, type: String

  belongs_to :user
  has_many :problems
  has_many :participants

  after_create :set_path, :create_folder, :create_template_problem
  before_destroy :clear  
  
  def set_path
    self.path = (Contest.exists?) ? 
      ( Contest.all.sort_by{|i| i.path.to_i}.last.path.to_i + 1 ).to_s : '1'
  end

  def create_folder
    FileUtils.mkdir_p self.contest_dir
  end

  def create_template_problem
    self.problems_create(0)
  end

  def clear
    #destroy all problems and submits
    self.problems.destroy_all
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

  def start(params, now = false)
    self.time_start = (now==true) ? DateTime.now : Contest.new(params).time_start
    self.duration = Contest.new(params).duration
  end

  def restart(params)
    self.participants.destroy_all
    #delete standings
    self.start(params, true)
  end

  def stop
    self.duration = 0
  end

  def continue(params)
    self.duration = self.get_left(true) + Contest.new(params).duration
  end

  def get_left(without = false)
    now = DateTime.now.to_time
    h2 = now.hour
    m2 = now.min
    con = self.time_start.to_time
    h1 = con.hour
    m1 = con.min
    left = ((h2 - h1)*60 + (m2 - m1))
    if without==true
      left
    else
      (self.duration > left && save) ? self.duration - left : 0
    end
  end
  # def unpack(archive)
  #   #create folder if not exist
  #   FileUtils.mkdir_p self.contest_dir
  #   #write archive_file(.zip) in contest_dir
  #   File.open(Rails.root.join(self.contest_dir, archive.original_filename), 'w') do |file|
  #     file.write(archive.read.force_encoding('utf-8'))
  #   end
  #   #exctract files(folders) from archive_file(.zip)
  #   Zip::ZipFile.open(self.contest_dir+"/#{archive.original_filename}"){ |zip_file|
  #     zip_file.each { |f|
  #       f_path=File.join(self.contest_dir, f.name)
  #       FileUtils.mkdir_p(File.dirname(f_path))
  #       zip_file.extract(f, f_path) unless File.exist?(f_path)
  #     }
  #   }
  #   #delete archive_file(.zip)
  #   FileUtils.remove_file(self.contest_dir+"/#{archive.original_filename}")
  # end

  def upd_problems_count(number)
    if self.problems_count > number
      self.problems_destroy(number+1, self.problems_count)

    elsif self.problems_count < number
      self.problems_create(self.problems_count+1, number)

    end
  end

  def problems_create(from, to=nil)
    to = from if to.nil?
    for i in from..to do
      problem = Problem.new({
        :contest => self,
        :order => i
      });
      #set template problems data
      problem.use_template if not problem.order == 0
      problem.save
      self.problems << problem
    end
    self.problems_count = self.problems.size - 1
    self.save
  end

  def problems_destroy(from, to=nil)
    to = from if to.nil?

    for i in from..to do
      #destory array's cell and object 
      self.problems.delete(self.problems.find_by(order: i)).destroy
    end
    self.problems_count = self.problems.size - 1
    self.save    
  end

  def upd_problems_template
    self.problems.each { |problem| problem.use_template }
  end

  # def put_statement(ufile)
  #   return if ufile.nil?

  #   statement_dir = self.contest_dir+'/statement'
  #   FileUtils.mkdir_p statement_dir
  #   File.open(Rails.root.join(statement_dir, ufile.original_filename), 'w') do |file|
  #     file.write(ufile.read.force_encoding('utf-8'))
  #   end
  #   self.statement_link = statement_dir+"/#{ufile.original_filename}"
  #   self.save
  # end
end

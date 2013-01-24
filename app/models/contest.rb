class Contest
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :title, type: String
  field :description, type: String
  field :path, type: String
  field :time_start, type: DateTime
  field :duration, type: Integer, :default => 300
  field :type, type: Integer #"ACM", "IOI"
  field :problems_count, type: Integer, :default => 0
  field :problems_upload, type: Integer #"one_archive", "every_problem"

  has_many :problems
  has_many :participants

  before_save :set_path
  
  def set_path
    return if self.path != nil
    self.path = (Contest.exists?) ? ( Contest.last.path.to_i + 1 ).to_s : '1'
  end

  before_destroy do |contest|
    #destroy all problems and submits
    contest.problems.each do |problem|
      problem.submits.destroy_all
      problem.destroy
    end
    #destroy all participants
    contest.participants.each { |participant| participant.destroy }
    #delete contest folder
    contest_dir = "#{Rails.root}/judge-files/contests/#{contest.path}"
    FileUtils.rm_rf contest_dir
  end

  def unpack(archive)
    contest_dir = "#{Rails.root}/judge-files/contests/#{self.path}"
    #create folder if not exist
    FileUtils.mkdir_p contest_dir unless File.directory? contest_dir
    #write archive_file(.zip) in contest_dir
    File.open(Rails.root.join(contest_dir, archive.original_filename), 'w') do |file|
      file.write(archive.read.force_encoding('utf-8'))
    end
    #exctract files(folders) from archive_file(.zip)
    Zip::ZipFile.open(contest_dir+"/#{archive.original_filename}"){ |zip_file|
      zip_file.each { |f|
        f_path=File.join(contest_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }
    #delete archive_file(.zip)
    FileUtils.remove_file(contest_dir+"/#{archive.original_filename}")
  end

  def problems_create
    #create contest_dir for 'one_archive' upload type
    contest_dir = "#{Rails.root}/judge-files/contests/#{self.path}" if self.problems_upload == 0
    for i in 1..self.problems_count
      problem = Problem.new({
        :contest => self,
        :order => i,
        :tests_path => (contest_dir.nil? ? nil : contest_dir+'/problems/'+i.to_s+'/tests')
      });
      problem.save
      self.problems << problem
    end
  end

end

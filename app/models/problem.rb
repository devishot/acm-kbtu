require 'zip/zipfilesystem'

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  field :global_path, type: String
  field :order, type: Integer
  field :tests_path, type: String
  field :statement, type: Hash #{:text => params[:text], :inputs => [], :outputs => []} || {:link=>''}

  belongs_to :contest
  has_many :submits


  before_save :set_global_path
  
  def set_global_path
    return if self.global_path != nil || self.contest.problems_upload == 0
    self.global_path = (Problem.exists? ? (Problem.last.global_path.to_i+1).to_s : '1')
  end


  def unzip(archive) 
    problem_dir = "#{Rails.root}/judge-files/problems/#{self.global_path}"
    FileUtils.mkdir_p problem_dir
    #write archive_file(.zip) in problem_dir
    File.open(Rails.root.join(problem_dir, archive.original_filename), 'w') do |file|
      file.write(archive.read.force_encoding('utf-8'))
    end
    #exctract files from file(.zip)
    Zip::ZipFile.open(problem_dir+"/#{archive.original_filename}"){ |zip_file|
      zip_file.each { |f|
        f_path=File.join(problem_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }
    #remove(delete) file(.zip)
    FileUtils.remove_file(problem_dir+"/#{archive.original_filename}")
    #set tests_path
    self.tests_path = problem_dir+"/tests"
  end
end

require 'zip/zipfilesystem'
require "#{Rails.root}/judge-files/check-system/compiler"

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  include Compiler
  field :order, type: Integer
  field :tests_path, type: String, :default => ''
  field :time_limit, type: Integer, :default => 2
  field :memory_limit, type: Integer, :default => 256
  field :checker, type: String, :default => 'cmp_file'
  field :checker_path, type: String
  field :global_path, type: String
  field :statement, type: Hash, :default =>
        {'title'=>'', 'text'=>'', 'inputs'=>[], 'outputs'=>[], 'file_link'=>''}

  belongs_to :contest
  has_many :submits


  after_create :set_global_path
  before_destroy :clear
  
  def set_global_path
    return if self.order==0
    return if not self.global_path.nil?
    self.global_path = (Problem.exists?) ? 
                    (Problem.all.sort_by{|i| i.global_path.to_i}.last.global_path.to_i+1).to_s 
                      : 
                    '1'
    self.save
  end

  def clear
    self.submits.destroy_all
    FileUtils.rm_rf self.tests_path
  end

  def use_template
    template = self.contest.problems[0]
    self.update_attributes(
        :time_limit => template.time_limit,
        :memory_limit => template.memory_limit,
        :checker => template.checker,
        :statement => {'file_link'=> template.statement['file_link']}
    )
  end

  def unzip(archive) 
    problem_dir = "#{Rails.root}/judge-files/problems/#{self.global_path}"
    #clear
    FileUtils.rm_rf problem_dir
    #create new
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

  def get_checker(ufile)
    problem_dir = "#{Rails.root}/judge-files/problems/#{self.global_path}"
    checker_dir = problem_dir + '/checker'
    #create new
    FileUtils.mkdir_p checker_dir
    #write ufile in problem_dir
    File.open(Rails.root.join(checker_dir, ufile.original_filename), 'w') do |file|
      file.write(ufile.read.force_encoding('utf-8'))
    end
    #compile
    status = Compiler.compile(checker_dir+'/'+ufile.original_filename)
    #raise "#{status['status']} || #{status['error']}"
    return status
  end
end

require 'zip/zipfilesystem'
require "#{Rails.root}/judge-files/check-system/compiler"

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  include Compiler
  field :order, type: Integer
  field :time_limit, type: Integer, :default => 2
  field :memory_limit, type: Integer, :default => 256
  field :checker, type: String, :default => 'cmp_file'
  field :checker_path, type: String #path to checker sourcecode, executable it is 'checker' file
  field :checker_mode, type: Integer, :default => 0 # 0-standart 1-template 2-own
  field :global_path, type: String
  field :statement, type: Hash, :default =>
        {'title'=>'', 'text'=>'', 'inputs'=>[], 'outputs'=>[], 'file_link'=>''}

  belongs_to :contest
  has_many :submits


  after_create :set_global_path, :create_folder
  before_destroy :clear
  
  def set_global_path
    return if self.order==0
    return if not self.global_path.nil?
    self.global_path = (Problem.exists?) ? 
       (Problem.all.sort_by{|i| i.global_path.to_i}.last.global_path.to_i+1).to_s : '1'
    self.save
  end

  def create_folder
    FileUtils.mkdir_p self.problem_dir
  end  

  def clear
    self.submits.destroy_all
    FileUtils.rm_rf self.problem_dir
  end

  def problem_dir
    self.contest.contest_dir+"/problems/#{self.order}"
  end

  def tests_dir
    self.problem_dir+"/tests"
  end

  def tests_uploaded?
    File.exist?( self.tests_dir )
  end

  def checker_dir
    self.problem_dir+"/checker"
  end

  def use_template
    return if self.id == self.template.id
    self.update_attributes(
        :time_limit   => self.template.time_limit,
        :memory_limit => self.template.memory_limit,
        :checker      => self.template.checker,
#       :checker_path => self.template.checker_path,
        :checker_mode => (self.template.checker_mode == 2) ? 1 : 0,        
        :statement    => {'file_link'=> self.template.statement['file_link']}
    )
  end

  def template
    return self.contest.problems.find_by(order: 0)
  end

  def put_tests(archive) 
    return if self.order==0
    extention = File.extname(archive.original_filename)
    return if not (extention=='.zip' || extention=='.tgz')
    tests_dir = self.tests_dir
    #clear & create new & write archive_file(.zip) in tests_dir
    FileUtils.rm_rf tests_dir
    FileUtils.mkdir_p tests_dir
    File.open(Rails.root.join(tests_dir, archive.original_filename), 'w') do |file|
      file.write(archive.read.force_encoding('utf-8'))
    end
    #exctract files from file
    if extention == '.zip'
      Zip::ZipFile.open(tests_dir+"/#{archive.original_filename}"){ |zip_file|
        zip_file.each { |f|
          f_path=File.join(tests_dir, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        }
      }
    elsif extention == '.tgz'
      puts "tar zxvf \'#{tests_dir+'/'+archive.original_filename}\'"
      pid, stdin, stdout, stderr = Open4::popen4 "tar zxvf \'#{tests_dir+'/'+archive.original_filename}\' -C \'#{tests_dir}\'"
    end
    #remove(delete) file
    FileUtils.remove_file(tests_dir+"/#{archive.original_filename}")
  end

  def put_checker(ufile)
    #self.order==0 || self.global_path.nil? -> self problem is template for contests problems
    checker_dir = self.checker_dir
    #clear & create new & write ufile(.cpp) in checker_dir
    FileUtils.rm_rf checker_dir
    self.checker_path = ''
    FileUtils.mkdir_p checker_dir
    File.open(Rails.root.join(checker_dir, ufile.original_filename), 'w') do |file|
      file.write(ufile.read.force_encoding('utf-8'))
    end
    #compile
    status = Compiler.compile(checker_dir+'/'+ufile.original_filename, true)#compile(file_path, checker=true)
    if status['status'] == 'OK'
      self.checker_path = checker_dir+'/'+ufile.original_filename
    else
      FileUtils.rm_rf checker_dir
      return status;
    end
    #check on tests
    if self.tests_uploaded? then
      Dir.entries(self.tests_dir).sort.each_slice(2) do |t|
        next if t[0] == '.'
        command = "\'#{self.checker_dir}/checker\' #{self.tests_dir+'/'+t[0]} #{self.tests_dir+'/'+t[1]} #{self.tests_dir+'/'+t[1]}"
#        puts command
        pid, stdin, stdout, stderr = Open4::popen4 command
        ignored, open4_status = Process::waitpid2 pid
        std_out = stdout.gets
        std_err = stderr.gets
        if open4_status.exitstatus > 0 then #OK is 0
          status['status'] = 'NW'
          status['error'] = []
          status['error'] << case open4_status.exitstatus
            when 4, 2; "PE"
            when 5, 1; "WA"
            else "SE"
          end
          status['error'] << std_err

          self.checker_path = ''
          FileUtils.rm_rf checker_dir
          return status;
        end
      end
    end

    return status
  end

  def check_problem(ufile)
    return if self.order==0
    #clear & create new & write ufile in solution_dir
    solution_dir = self.problem_dir+"/solution"
    FileUtils.rm_rf solution_dir
    FileUtils.mkdir_p solution_dir    
    File.open(Rails.root.join(solution_dir, ufile.original_filename), 'w') do |file|
      file.write(ufile.read.force_encoding('utf-8'))
    end
    #send to check
    submit = Submit.new({
      :problem => self,
      :file_sourcecode_path => solution_dir+'/'+ufile.original_filename
    })
    submit.save
    Resque.enqueue(Tester, submit.id, true) #Tester(submit.id, hidden=true)
    return submit.id
  end

end

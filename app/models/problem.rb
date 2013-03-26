require 'zip/zipfilesystem'
require 'fileutils'
require "#{Rails.root}/judge-files/check-system/compiler"

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  include Compiler
  field :order, type: Integer
  field :global_path, type: String
  field :time_limit, type: Integer, :default => 2 #seconds
  field :memory_limit, type: Integer, :default => 256 #Megabytes
  field :input_file, type: String # nil || 'input.txt' || 'a.in'
  field :output_file, type: String
  field :checker_mode, type: Integer, :default => 0 # 0-standart 1-template 2-own  
  field :checker, type: String, :default => 'cmp_file'
  field :checker_path, type: String #path to checker sourcecode, executable it is 'checker' file
  field :statement, type: Hash, :default =>
        {'title'=>'', 'text'=>'', 'inputs'=>[], 'outputs'=>[], 'file_link'=>''}
  field :checked, type: String

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
    #raise self.inspect
    FileUtils.rm_rf self.problem_dir    
    self.submits.destroy_all
  end

  def problem_dir
    #raise self.contest.inspect
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

  def solution_dir
    self.problem_dir+"/solution"    
  end

  def use_template
    return if self.id == self.template.id
    self.update_attributes(
        :time_limit   => self.template.time_limit,
        :memory_limit => self.template.memory_limit,
        :input_file => self.template.input_file,
        :output_file => self.template.output_file,
        :checker      => self.template.checker,
#       :checker_path => self.template.checker_path,
        :checker_mode => (self.template.checker_mode == 2) ? 1 : 0,        
#       :statement    => {'file_link'=> self.template.statement['file_link']}
    )
  end

  def template
    return self.contest.problems.find_by(order: 0)
  end

  def put_statement(ufile, template=false)
    dir = (template) ? self.contest.contest_dir : self.problem_dir
    #delete previous file IF exist
    if not self.statement['file_link'].blank?
      File.delete File.join(dir, self.statement['file_link'])
      statement['file_link'] = nil
    end

    File.open(Rails.root.join(dir, ufile.original_filename), 'w') do |file|
      file.write(ufile.read.force_encoding('utf-8'))
    end
    self.statement[:file_link] = dir+'/'+ufile.original_filename
  end

  def get_statement
    statement = self.statement['file_link']
    return if statement.blank?

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
      pid, stdin, stdout, stderr = Open4::popen4 "tar zxvf \'#{tests_dir+'/'+archive.original_filename}\' -C \'#{tests_dir}\'"
      ignored, status = Process::waitpid2 pid
    end
    #remove(delete) file
    File.delete File.join(tests_dir, archive.original_filename)
            # #check count of tests
            # tests_count = Dir.entries(problems_dir).count - 2
            # if tests_count<2 || tests_count.modulo(2)==1
            #   ret_status['error'] << "  Error: There is only #{tests_count}"
            #   next
            # end
            # #tests checked, ok    
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
      self.checker_mode = 2
      #check on tests
      if self.tests_uploaded? then
        Dir.entries(self.tests_dir).sort[2..-1].each_slice(2) do |t|
          #puts "#{self.tests_dir} | #{t[0]} | #{t[1]}"
          next if not File.basename(t[0], '.*') == File.basename(t[1], '.*') 
          #puts "#{self.tests_dir} | #{t[0]} | #{t[1]}"          
          command = "\'#{self.checker_dir}/checker\' \'#{self.tests_dir+'/'+t[0]}\' \'#{self.tests_dir+'/'+t[1]}\' \'#{self.tests_dir+'/'+t[1]}\'"
          #puts command
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
            self.checker_mode = 0
            FileUtils.rm_rf checker_dir
            return status;
          end
        end
      end
      self.checker_path = checker_dir+'/'+ufile.original_filename
      self.checker_mode = 2
    else
      FileUtils.rm_rf checker_dir
    end

    return status
  end

  #put_solution
  def check_problem(ufile) 
    return if self.order==0
    #clear & create new & write ufile in solution_dir
    solution_dir = self.solution_dir
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
    self.checked = submit.id
  end

  def check_problem_again
    solution_file = nil
    Dir.entries(self.solution_dir).sort[2..-1].each do |t|
      if ['.pas', '.dpr', '.cpp'].include? t
        solution_file = self.solution_dir+'/'+solution_file
        break
      end
    end
    return if solution_file.nil?

    solution = ActionDispatch::Http::UploadedFile.new({
      :filename => "#{File.basename(solution_file)}",
      :tempfile => File.new(solution_file)
    })
    self.check_problem( solution )      
  end

  def get_checked_status
    return nil if self.checked.nil?
    submit = Submit.find( self.checked )
    return submit.status
  end

end

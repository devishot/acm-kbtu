require 'zip/zipfilesystem'
require 'fileutils'
require "#{Rails.root}/judge-files/check-system/compiler"

class Problem
  include Mongoid::Document
  include Mongoid::Timestamps
  include Compiler
  field :order,         type: Integer
  field :global_path,   type: String
  field :time_limit,    type: Integer,  :default => 2 #seconds
  field :memory_limit,  type: Integer,  :default => 256 #Megabytes
  field :input_file,    type: String    # nil || 'input.txt' || 'a.in'
  field :output_file,   type: String
  field :checker_mode,  type: Integer,  :default => 0 # 0-standart 1-template 2-own  
  field :checker,       type: String,   :default => 'fcmp'
  field :checker_path,  type: String    #path to checker sourcecode, executable file is 'checker'
  field :solution_file, type: String
  field :checked,       type: String
  field :statement,     type: Hash,     :default =>
        {'title'=>'', 'text'=>'', 'inputs'=>[], 'outputs'=>[], 'file_link'=>''}
  field :disabled,      type: Boolean,  :default => false

  belongs_to  :contest
  has_many    :submits


  after_create    :set_global_path, :create_folder
  before_destroy  :clear
  
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
    (File.directory?(self.tests_dir) && Dir.entries(self.tests_dir).size>2)
  end

  def checker_dir
    self.problem_dir+"/checker"
  end

  def solution_dir
    self.problem_dir+"/solution"
  end

  def statement_dir
    self.problem_dir+"/statement"
  end

  def order_abc
    return self.contest.problems_count>26 ? self.order : (self.order+64).chr
  end

  def template
    return self.contest.problems.find_by(order: 0)
  end

  def use_template
    return if self.order == 0
    self.update_attributes(
        :time_limit   => self.template.time_limit,
        :memory_limit => self.template.memory_limit,
        :input_file => self.template.input_file,
        :output_file => self.template.output_file,
        :checker      => self.template.checker,
    )
    if self.template.checker_mode == 2
      self.update_attributes(
        :checker_path => self.template.checker_path,
        :checker_mode => 1,
      )
    else
      self.update_attributes(
        :checker_mode => 0,
      )      
    end
  end

  def put_problem(params)
    @status = {:notice => [], :alert => []}

    #Contest: put 'archive of problems' IF @problem.order==0 && 'problems' uploaded
    if not params[:problems].nil?
      problems_status = self.contest.put_problems(params[:problems]) 
      @status[:notice] << 'Contest: archive of problems uploaded'
      problems_status[:notice].each {|x| @status[:notice] << x } if not problems_status[:notice].nil?
      problems_status[:error].each {|x| @status[:alert] << x } if not problems_status[:error].nil?
      return @status
    end

    #Contest: put statement
    if not params[:statement].nil?
      self.put_statement(params[:statement])
      @status[:notice] << 'Contest: statement added'
    end

    #put tests if uploaded
    if not params[:tests_archive].nil?
      tests_status = self.put_tests(params[:tests_archive])

      if tests_status[:status] == 'OK'
        @status[:notice] << 'Tests uploaded'
      else
        @status[:alert]  << 'Tests not uploaded:'
        tests_status[:error].each {|x| @status[:alert] << '---'+x } if not tests_status[:error].nil?
      end
    end

    #put checker if uploaded
    if not params[:problem][:uploaded_checker].nil?
      checker_status = self.put_checker(params[:problem][:uploaded_checker])

      if checker_status[:status] == 'OK'
        @status[:notice] << 'Checker compiled'

      elsif checker_status[:status] == 'CE'
        @status[:alert] << 'Checker was not compiled(CE):'
        checker_status[:error].each {|x| @status[:alert] << '---'+x } if not checker_status[:error].nil?

      elsif checker_status[:status] == 'SE'
        @status[:alert] << 'Checker is incorect(SE):'
        checker_status[:error].each {|x| @status[:alert] << '---'+x } if not checker_status[:error].nil?
      end
      params[:problem].delete(:uploaded_checker)
      params[:problem].delete(:checker_mode)
    end

    #set template's Checker IF own checker not uploaded
    if self.checker_path.blank? && self.checker_mode==2
      self.checker_mode = (self.template.checker_mode==2) ? 1 : 0
    end

    #update params
    r = self.update_attributes(params[:problem])
    if r == true
      @status[:notice] << 'Problem updated'
    else
      @status[:alert]  << 'Problem not updated'
    end

    #put solution and CHECK TESTS AND CHECKER
    if not params[:solution_file].nil?
      solutions_status = self.put_solution(params[:solution_file])
      if solutions_status[:status] == 'OK'
        @status[:notice] << 'solution added, problem checked'
      else
        @status[:alert]  << "solution is incorrect, got a #{solutions_status[:status]}"
        solutions_status[:error].each {|x| @status[:alert] << '|   '+x } if not solutions_status[:error].nil?
      end
    #check again IF was uploaded
    elsif not self.checked.nil?
      solutions_status = self.put_solution() #REcheck with uploaded solution
      if solutions_status[:status] == 'OK'
        @status[:notice] << 'problem REchecked'
      else
        @status[:alert]  << "solution is incorrect, got a #{solutions_status[:status]}"
        solutions_status[:error].each {|x| @status[:alert] << '|   '+x } if not solutions_status[:error].nil?
      end
    end

    #Contest: push new template for all problems
    if self.order==0
      self.contest.upd_problems_template
      @status[:notice] << 'Contest: template pushed'
    end

    #save
    self.save

    return @status
  end

  def put_tests(archive)
    return if self.order==0
    status = {:status => '', :error => []}
    tests_dir = self.tests_dir
    #check extantion
    extention = File.extname(archive.original_filename)
    if not (extention=='.zip' || extention=='.tgz')
      status[:status] = 'SE'
      status[:error] << "extention \'#{extention}\' not supported"
      return status
    end
    #clear & create new & write archive in tests_dir
    FileUtils.rm_rf tests_dir
    FileUtils.mkdir_p tests_dir
    File.open(Rails.root.join(tests_dir, archive.original_filename), 'w') do |file|
      file.write(archive.read.force_encoding('utf-8'))
    end
    #exctract files from archive
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
      ignored, open4_status = Process::waitpid2 pid
    end
    #remove(delete) archive
    File.delete File.join(tests_dir, archive.original_filename)

    #IF in folder THEN extract from
    if Dir.entries(tests_dir).count - 2 == 1
      f = (Dir.entries(tests_dir)-[".", ".."])[0]
      if File.directory? tests_dir+"/#{f}"
        #raise Dir.entries(tests_dir+"/#{f}").inspect
        FileUtils.cp_r tests_dir+"/#{f}/.", tests_dir
        #raise Dir.entries(tests_dir).inspect
        FileUtils.rm_rf tests_dir+"/#{f}"
      end
    end
    #check number of tests
    tests_count = Dir.entries(tests_dir).count - 2    
    if tests_count<2 || tests_count.modulo(2)==1
      status[:status] = 'SE'
      status[:error] << "there is only #{tests_count} files"
      FileUtils.rm_rf tests_dir
      return status
    end
    #check pairs of tests
    Dir.entries(tests_dir).sort[2..-1].each_slice(2) do |t|
      if not File.basename(t[0], '.*') == File.basename(t[1], '.*')
        status[:status] = 'SE'
        status[:error] << "test | #{t[0]} : #{t[1]} | is incorrect"
        FileUtils.rm_rf tests_dir        
        return status
      end
    end
    #tests checked, OK
    status[:status] = 'OK'
    return status
  end

  def put_checker(ufile)
    status = {:status => '', :error => []}
    checker_dir = self.checker_dir
    #clear & create new & write ufile(.cpp) in checker_dir
    FileUtils.rm_rf checker_dir
    self.checker_path = ''
    self.checker_mode = 0
    FileUtils.mkdir_p checker_dir
    File.open(Rails.root.join(checker_dir, ufile.original_filename), 'w') do |file|
      file.write(ufile.read.force_encoding('utf-8'))
    end
    #compile checker |compile(source file path, destination file, checker=false)
    compile_status = Compiler.compile(checker_dir+'/'+ufile.original_filename, checker_dir+'/checker', true)
    if compile_status[:status] == 'OK'
      self.checker_path = checker_dir+'/'+ufile.original_filename
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
            status[:status] = 'SE'
            status[:error] << "checker on test | #{t[0]} : #{t[1]} | got:"
            status[:error] << case open4_status.exitstatus
              when 4, 2; "PE"
              when 5, 1; "WA"
              else "SE"
            end
            std_err.each {|x| status[:error] << x} if not std_err.nil?
            break;
          end
        end
      end
      status[:status] = 'OK' if status[:status].empty?        
    else
      status = compile_status
    end

    if status[:status] == 'OK'
      self.checker_mode = 2
    else
      #delete checker
      self.checker_path = ''
      self.checker_mode = 0
      FileUtils.rm_rf checker_dir
    end
#    self.save

    return status;
  end

  def put_solution(ufile='recheck')
    return if self.order==0

    require "#{Rails.root}/judge-files/check-system/run"
    status = {:status => '', :error => [], :test => ''}
    solution_dir = self.solution_dir

    if not ufile == 'recheck'
      #clear & create new & write ufile in solution_dir
      FileUtils.remove_dir solution_dir, true
      FileUtils.mkdir_p    solution_dir
      File.open(Rails.root.join(solution_dir, ufile.original_filename), 'w') do |file|
        file.write(ufile.read.force_encoding('utf-8'))
      end
      self.solution_file = solution_dir+'/'+ufile.original_filename
    end
    #send to check
    submit = Submit.create({
      :problem    => self,
      :sourcecode => self.solution_file,
      :hidden     => true
    })
    self.checked = submit.id
    Tester.perform(submit.id, true) #Tester(submit.id, hidden=true)
    #parse status
    while true
      submit.reload
      break if not submit.status.empty?
    end
    if submit.status['status'] == 'AC'
      status[:status] = 'OK'
    else
      status[:status] = submit.status['status']
      submit.status['error'].each {|x| status[:error] << x } if not submit.status['error'].nil?
      status[:test] = submit.status['test']
    end
    return status
  end

  def get_solution
    return nil if self.checked.nil?
    return Submit.find( self.checked )
  end

  def put_statement(ufile)
    statement_dir = self.statement_dir
    #delete previous statement file IF exist
    if not self.statement['file_link'].blank?
      File.delete self.statement['file_link']
      statement['file_link'] = nil
    end
    FileUtils.mkdir_p statement_dir
    #raise Rails.root.join(statement_dir, ufile.original_filename).inspect
    #write and save
    File.open(Rails.root.join(statement_dir, ufile.original_filename), 'w') do |file|
      file.write(ufile.read.force_encoding('utf-8'))
    end
    self.statement[:file_link] = statement_dir+'/'+ufile.original_filename
  end
end

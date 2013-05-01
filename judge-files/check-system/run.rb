require 'fileutils'
require 'open4'
require 'date'
require 'resque'
require "#{Rails.root}/judge-files/check-system/compiler"

class Tester
  attr_accessor :init_status
  @queue = :simple

  def initialize(submit_id, hidden=false)
    @init_status = false

    @submit = Submit.find(submit_id)
    @submit.status = {:status => '', :error => [], :test => ''}
    @source_code = @submit.sourcecode
    @source_code_ext = File.extname(@source_code)    
    #check source_code
    if not File.file? @source_code
      @submit.status = {:status => 'SE', :error => ["source code not found", @source_code]}
      @submit.save
      return
    end

    @problem = @submit.problem
    @tests_path = @problem.tests_dir
    #check tests
    if not @problem.tests_uploaded?
      @submit.status = {:status => 'SE', :error => ["tests not found"]}
      @submit.save
      return
    end

    #get work_dir
    @contest = @problem.contest
    if hidden==false
      @participant = @submit.participant
      @work_dir = "#{@@system_path}/tmp/contest #{@contest.path}/participant #{@participant.path}/submit #{@submit.order}"
    else
      @work_dir = "#{@@system_path}/tmp/contest #{@contest.path}(hidden)"
      FileUtils.rm_r @work_dir
    end
    FileUtils.mkdir_p @work_dir
    
    #get checker
    if @problem.checker_mode==0
      @checker = "#{@@system_path}/checkers/#{@problem.checker}"
    elsif @problem.checker_mode==1
      @checker = "#{@problem.template.checker_dir}/checker"
    else @problem.checker_mode==2
      @checker = "#{@problem.checker_dir}/checker"
    end
    #check checker
    if not File.executable? @checker
      @submit.status = {:status => 'SE', :error => ["checker not found, #{@checker}"]}
      @submit.save      
      return
    end

    @submit.save
    @init_status = true
  end


  def check(tin, tout, output_file)
    if @submit.problem.checker_mode == 0 #system
      checker = "\'#{@@system_path}/checkers/#{@problem.checker}\' "
    elsif @submit.problem.checker_mode == 2 #own
      checker = "\'#{@problem.checker_dir}/checker\' "
    elsif @submit.problem.checker_mode == 1 #template
      checker = "\'#{@problem.template.checker_dir}/checker\' "
    end
    command = checker + "\'#{@tests_path}/#{tin}\' " +
                        "\'#{@work_dir}/#{output_file}\' " +
                        "\'#{@tests_path}/#{tout}\'"
    pid, stdin, stdout, stderr = Open4::popen4 command
    ignored, open4_status = Process::waitpid2 pid

    std_out = stdout.readlines
    std_err = stderr.readlines
    #puts "!2   #{std_err} | #{std_out}"
    @submit.status[:status] = case open4_status.exitstatus
      when 0; "OK"
      when 4, 2; "PE"
      when 5, 1; "WA"
      else "SE" 
    end
    if not std_out.blank?
      @submit.status[:error] << 'OutputStream:'
      std_out.each { |x| @submit.status[:error] << x }
    end
    if not std_err.blank?
      @submit.status[:error] << 'ErrorStream:'
      std_err.each { |x| @submit.status[:error] << x }
    end

    return (open4_status.exitstatus==0) ? true : false;
  end


  def run()
    #compile sourcecode
    compile_status = Compiler.compile(@source_code, "#{@work_dir}/solution")
    if not compile_status[:status] == 'OK' then
      @submit.status = compile_status
      @submit.save
      return
    end

    #get every test(pair of 'file' and 'file.ans', or 'file.in' and 'file.out')
    k = 0 #number of test's pairs
    Dir.entries(@tests_path).sort[2..-1].each_slice(2) do |t|
      next if not File.basename(t[0], '.*') == File.basename(t[1], '.*')
      k = k + 1

      input_file  = @problem.input_file
      output_file = @problem.output_file
      #copy current test's input to input for solution
      FileUtils.cp @tests_path+'/'+t[0], "#{@work_dir}/#{(input_file.blank?) ? 'input.txt' : input_file}"
      #RUN solution
      command = "\'#{@@system_path}/ejudge-execute\' " +
                "\'--workdir=#{@work_dir}\' " +
                "\'--time-limit=#{@problem.time_limit}\' " +
                "\'--max-vm-size=#{@problem.memory_limit}M\' " +
                "\'--memory-limit\' " +
                "#{(input_file.blank?)  ? "\'--stdin=#{@work_dir}/input.txt\'"   : nil} " +
                "#{(output_file.blank?) ? "\'--stdout=#{@work_dir}/output.txt\'" : nil} " +
                "\'#{@work_dir}/solution\'"
      pid, stdin, stdout, stderr = Open4::popen4 command
      ignored, open4_status = Process::waitpid2 pid
      verdict = stderr.readlines

      #raise "#{File.exist?(@@system_path+'/ejudge-execute ')} #{File.exist?(@@system_path+'/ejudge-execute')} #{File.exist?(@@system_path+'/ejudge-execute')}"

      if not verdict[0][8,9].strip == 'OK'
        @submit.status[:status] = verdict[0][8,9].strip
        @submit.status[:error]  = verdict
        @submit.save
        
        return
      else
        #puts "!1  #{t[0]} | #{t[1]} | #{verdict}"
        #CHECK(COMPARE answer and test's answer)
        f = self.check(t[0], t[1], (output_file.blank?) ? 'output.txt' : output_file)
        if f == false
          @submit.status[:test] = k
          @submit.save
          return
        end
      end
    end

    @submit.status = {:status => 'AC'}
    @submit.save
    return
  end


  def self.perform(submit_id, hidden=false)
    @@system_path = "#{Rails.root}/judge-files/check-system"

    a = Tester.new(submit_id, hidden)
    if( a.init_status==true )
      a.run
    else
      return
    end

    #skip set standing
    return if hidden==true


    #//standings
    @submit = Submit.find(submit_id)
    @participant = @submit.participant
    @problem = @submit.problem

    if @submit.status['status'] == "AC"
      if @participant.a[@problem.order] <= 0
        #p "AC"
        @participant.a[@problem.order] = @participant.a[@problem.order].abs+1
        #p @participant.a
        @participant.penalties[@problem.order] += ((Time.now.to_i - @participant.contest.time_start.to_i)/60).to_i
        #p @participant.penalties
        @participant.save!
      end
    elsif ['WA', 'TL', 'RT', 'PT', 'SE'].include? @submit.status['status'] 
      if @participant.a[@problem.order] <= 0
        #p "WA"
        @participant.a[@problem.order] -= 1
        @participant.penalties[@problem.order] += 20
        @participant.save!
      end
    end
  end
end
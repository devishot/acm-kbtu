require 'fileutils'
require 'open4'
require 'date'
require 'resque'
require "#{Rails.root}/judge-files/check-system/compiler"

class Tester
  @queue = :simple

  def put_sourcecode
    #delete and create new work directory
    FileUtils.remove_dir @work_dir if File.exist? @work_dir
    FileUtils.mkdir_p @work_dir
    #copy sourcecode in 1.cpp
    FileUtils.cp @submit.file_sourcecode_path, "#{@work_dir}solution#{@src_ext}"
  end

  def initialize(submit_id, system_path, hidden=false)
    @submit = Submit.find(submit_id)
    @source_code = @submit.file_sourcecode_path
    @source_code_ext = File.extname(@source_code)    
    #check source_code
    if not File.file? @source_code
      @submit.status = {"status" => 'SE', "error" => "source code not found, #{@source_code}"}
      @submit.save
      return false
    end

    @problem = @submit.problem
    @tests_path = @problem.tests_dir
    #check tests
    if not @problem.tests_uploaded?
      @submit.status = {"status" => 'SE', "error" => "tests not found"}
      @submit.save      
      return false
    end

    #get work_dir
    @contest = @problem.contest
    if hidden==false
      @participant = @submit.participant
      @work_dir = "#{Rails.root}/contests/#{@contest.path}/submits/participant#{@participant.path}/submit#{@submit.order}"
    else
      @work_dir = "#{system_path}/tmp"
      FileUtils.rm_r @work_dir
    end
    FileUtils.mkdir_p @work_dir
    
    if @problem.checker_mode==0
      @checker = "#{system_path}/checkers/#{@problem.checker}"
    elsif @problem.checker_mode==1
      @checker = "#{@problem.template.checker_dir}/checker"
    else @problem.checker_mode==2
      @checker = "#{@problem.checker_dir}/checker"
    end
    #check checker
    if not File.executable? @checker
      @submit.status = {"status" => 'SE', "error" => "checker not found, #{@checker}"}
      @submit.save      
      return false
    end

    return true
  end


  def check(tin, tout, output_file)
    if @submit.problem.checker_mode == 0 #system
      checker = "\'#{@work_dir}../../checkers/#{@submit.problem.checker}\' "
    elsif @submit.problem.checker_mode == 2 #own
      checker = "\'#{@submit.problem.checker_dir}/checker\' "
    elsif @submit.problem.checker_mode == 1 #template
      checker = "\'#{@submit.problem.contest.problems.find_by(order: 0).checker_dir}/checker\' "
    end
    command = checker + "\'#{@tests_path}/#{tin}\' " +
                        "\'#{@work_dir}#{output_file}\' " +
                        "\'#{@tests_path}/#{tout}\'"
    #puts command
    pid, stdin, stdout, stderr = Open4::popen4 command
    ignored, status = Process::waitpid2 pid

    std_out = stdout.readlines
    std_err = stderr.readlines

    #puts "!2   #{std_err} | #{std_out}"

    @submit.status['status'] = case status.exitstatus
      when 0; "OK"
      when 4, 2; "PE"
      when 5, 1; "WA"
      else "SE" 
    end
    @submit.status['error'] = std_out

    return (status.exitstatus==0) ? true : false;
  end

  def run()
    #//compile sourcecode
    @submit.status = Compiler.compile("#{@work_dir}solution#{@src_ext}")
    if @submit.status['status'] == 'CE' then
      @submit.save
      return
    end

    #//get every test(pair of 'file' and 'file.ans')
    k = 0;
    Dir.entries(@tests_path).sort[2..-1].each_slice(2) do |t|
      next unless File.basename(t[0], '.*') == File.basename(t[1], '.*')
      k = k + 1

      input_file  = @submit.problem.input_file
      output_file = @submit.problem.output_file
      #copy current test's input to work/input.txt file      
      FileUtils.cp @tests_path+'/'+t[0], "#{@work_dir}#{(input_file.blank?) ? 'input.txt' : input_file}"
      #//RUN
      command = "\'#{@work_dir}../../ejudge-execute\' " +
                "--workdir=#{@work_dir} " + 
                "--time-limit=#{@submit.problem.time_limit} " +
                "--max-vm-size=#{@submit.problem.memory_limit}M " +
                "--memory-limit " +
                "#{(input_file.blank?) ? "--stdin=\'#{@work_dir}input.txt\'" : nil} " +
                "#{(output_file.blank?) ? "--stdout=\'#{@work_dir}output.txt\'" : nil} " +
                "\'#{@work_dir}solution\'"
      pid, stdin, stdout, stderr = Open4::popen4 command
      ignored, status = Process::waitpid2 pid
      verdict = stderr.readlines

      @submit.status['status'] = verdict[0][8,9].strip
      @submit.status['error'] = verdict      
      #puts "!1  #{t[0]} | #{t[1]} | #{verdict}"
      if @submit.status['status'] == 'OK'
        #//CHECK(COMPARE)
        if not self.check(t[0], t[1], (output_file.blank?) ? 'output.txt' : output_file)
          @submit.status['test'] = k
          @submit.save
          return
        end
      else
        @submit.save
        return
      end
    end

    @submit.status = {"status" => 'AC'}
    @submit.save
    return
  end

  def self.perform(submit_id, hidden=false)
    system_path = "#{Rails.root}/judge-files/check-system"

    @submit = Submit.find(submit_id)
    @submit.status['status'] = 'SE'
    @submit.save!
    puts @submit.inspect
    return
    raise @submit.inspect

    if (a = Tester.new(submit_id, system_path, hidden))==true
      a.run 
    end
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
    elsif @submit.status['status'] == "WA"
      if @participant.a[@problem.order] <= 0
        #p "WA"
        @participant.a[@problem.order] -= 1
        @participant.penalties[@problem.order] += 20
        @participant.save!
      end
    end
  end
end
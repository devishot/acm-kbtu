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

  def initialize(submit_id, system_path)
    @submit = Submit.find(submit_id)
    @work_dir = "#{system_path}/work/"
    @tests_path = @submit.problem.tests_dir
    @src_ext = File.extname(@submit.file_sourcecode_path)

    self.put_sourcecode
  end


  def check(tin, tout)
    if @submit.problem.checker_mode == 0 #system
      checker = "\'#{@work_dir}../checkers/#{@submit.problem.checker}\' "
    elsif @submit.problem.checker_mode == 2 #own
      checker = "\'#{@submit.problem.checker_dir}/checker\' "
    elsif @submit.problem.checker_mode == 1 #template
      checker = "\'#{@submit.problem.contest.problems.find_by(order: 0).checker_dir}/checker\' "      
    end
    command = checker + " \'#{@tests_path}/#{tin}\' " +
              "\'#{@work_dir}output.txt\' " + "\'#{@tests_path}/#{tout}\'"

    #puts command
    pid, stdin, stdout, stderr = Open4::popen4 command
    ignored, status = Process::waitpid2 pid

    std_out = stdout.readlines
    std_err = stderr.readlines

    puts "!2   #{std_err} | #{std_out}"

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
    #puts "Compiled\n"

    #//get every test(pair of 'file' and 'file.ans')
    k = 0;
    Dir.entries(@tests_path).sort.each_slice(2) do |t|
      next unless File.basename(t[0], '.*') == File.basename(t[1], '.*')
      k = k + 1
      #copy current test's input to work/input.txt file      
      FileUtils.cp @tests_path+'/'+t[0], "#{@work_dir}input.txt"
      #//RUN
      pid, stdin, stdout, stderr = 
        Open4::popen4 "\'#{@work_dir}../ejudge-execute\' " +
                      "--time-limit=#{@submit.problem.time_limit} " +
                      "--max-vm-size=#{@submit.problem.memory_limit}M " +
                      "--memory-limit " + 
                      "--stdin=\'#{@work_dir}input.txt\' " +
                      "--stdout=\'#{@work_dir}output.txt\' " +
                      "\'#{@work_dir}solution\'"                      
      verdict = stderr.readlines

      @submit.status['status'] = verdict[0][8,9].strip
      @submit.status['error'] = verdict      
      puts "!1  #{t[0]} | #{t[1]} | #{verdict}"      
      if @submit.status['status'] == 'OK'
        #//CHECK(COMPARE)
        if not self.check(t[0], t[1])
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

    a = Tester.new(submit_id, system_path)
    a.run
    return if hidden==true


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
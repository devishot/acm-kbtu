require 'fileutils'
require 'open4'
require 'date'
require 'resque'

class Tester
  @queue = :simple

  def initialize(submit_id, system_path)
    @submit = Submit.find(submit_id)
    @work_dir = "#{system_path}/work/"
    @tests_path = @submit.problem.tests_path
  end

  def compile()
    #delete and create new work directory
    FileUtils.remove_dir @work_dir if File.exist? @work_dir
    FileUtils.mkdir @work_dir
    #copy sourcecode in 1.cpp
    FileUtils.cp @submit.file_sourcecode_path, "#{@work_dir}1.cpp"

    pid, stdin, stdout, stderr = Open4::popen4 "g++ \'#{@work_dir}1.cpp\' -o \'#{@work_dir}1.exe\'"
    compile_err = stderr.gets #we need to save, it will changed

    if compile_err.nil?
      @submit.status = "OK"
      @submit.status_full = ""
      return 1
    else
      @submit.status = "CE"
      @submit.status_full = compile_err
      return 0
    end
  end

  def check(tin, tout)
    pid, stdin, stdout, stderr = 
      Open4::popen4 "\'#{@work_dir}../checkers/#{@submit.problem.checker}\' " +
                    "\'#{@tests_path}/#{tin}\' " +
                    "\'#{@work_dir}output.txt\' " + 
                    "\'#{@tests_path}/#{tout}\'"
    ignored, status = Process::waitpid2 pid

    std_out = stdout.gets
    std_err = stderr.gets

    puts "#{std_err} \n #{std_out}"

    @submit.status = case status.exitstatus
      when 0; "OK"
      when 4, 2; "PE"
      when 5, 1; "WA"
      else "SE" 
    end
    @submit.status_full = (@submit.status=="SE") ? "" : "#{status} | #{std_err} | #{std_out}"

    return (status.exitstatus==0) ? 1 : 0; #// @submit.status==0 <- "OK"
  end

  def run()
    #//compile sourcecode
    if self.compile == 0
      @submit.save
      return 0
    end
    #//get every test(pair of 'file' and 'file.smth')
    Dir.entries(@tests_path).sort.each_slice(2) do |t|
      next if t[0] == '.'
      #copy current test's input to work/input.txt file      
      FileUtils.cp @tests_path+'/'+t[0], "#{@work_dir}input.txt"
      #//RUN
      pid, stdin, stdout, stderr = 
        Open4::popen4 "\'#{@work_dir}../ejudge-execute\' " +
                      "--time-limit=#{@submit.problem.time_limit} " +
                      "--stdin=\'#{@work_dir}input.txt\' " +
                      "--stdout=\'#{@work_dir}output.txt\' " +
                      "\'#{@work_dir}1.exe\'"
      verdict = stderr.gets
      verdict = verdict[8,9].strip

      if verdict == 'OK'
        #//CHECK(COMPARE)
        if self.check(t[0], t[1]) == 0
          @submit.save
          return 0
        end
      else
        @submit.status = verdict  #// TL or other errors
        @submit.status_full = ""
        @submit.save
        return 0
      end
    end

    @submit.status = "AC"
    @submit.status_full = ""
    @submit.save
    return 1
  end

  def get_status
    return self.submit.status
  end

  def self.perform(submit_id)
    system_path = "#{Rails.root}/judge-files/check-system"

    a = Tester.new(submit_id, system_path)
    a.run


    @submit = Submit.find(submit_id)
    @participant = @submit.participant
    @problem = @submit.problem

    if @submit.status == "AC"
      if @participant.a[@problem.order] <= 0
        #p "AC"
        @participant.a[@problem.order] = @participant.a[@problem.order].abs+1
        #p @participant.a
        @participant.penalties[@problem.order] += ((Time.now.to_i - @participant.contest.time_start.to_i)/60).to_i
        #p @participant.penalties
        @participant.save!
      end
    elsif @submit.status == "WA"
      if @participant.a[@problem.order] <= 0
        #p "WA"
        @participant.a[@problem.order] -= 1
        @participant.penalties[@problem.order] += 20
        @participant.save!
      end
    end
  end
end
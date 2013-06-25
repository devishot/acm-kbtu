require 'fileutils'
require 'open4'
require 'date'
require 'resque'
require "#{Rails.root}/judge-files/check-system/compiler"

class Tester
  attr_accessor :init_status
  @queue = :submits

  def initialize(submit_id, hidden=false)
    @init_status = false

    @submit = Submit.find(submit_id)
    @submit.status = {:status => '', :error => [], :test => ''}
    @submit.tests_status = [{}] #empty, full in Run
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

    @submit.save!
    @init_status = true
  end


  def check(tin, tout, output_file, test_number)
    checker_status = {:status => '', :error => []}

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
    checker_status[:status] = case open4_status.exitstatus
      when 0; "OK"
      when 4, 2; "PE"
      when 5, 1; "WA"
      else "SE" 
    end

    if not std_out.blank?
      checker_status[:error] << 'OutputStream:'
      std_out.each { |x| checker_status[:error] << x }
    end

    if not std_err.blank?
      checker_status[:error] << 'ErrorStream:'
      std_err.each { |x| checker_status[:error] << x }
    end

    return checker_status
  end

  def run()
    #compile sourcecode
    compile_status = Compiler.compile(@source_code, "#{@work_dir}/solution")
    if not compile_status[:status] == 'OK' then
      @submit.status = compile_status
      @submit.save!
      return
    end
    if @contest.type==1#IOI
      @submit.status[:status] = "OK"
      @submit.save!
    end

    #get every test(pair of 'file' and 'file.ans', or 'file.in' and 'file.out')

    ## sort{|a,b| if a.size==b.size then a<=>b else a.size <=> b.size end }
    Dir.entries(@tests_path).sort[2..-1].each_slice(2).with_index do |t, i|
      next if not File.basename(t[0], '.*') == File.basename(t[1], '.*')
      #puts "#{i}:  #{t[0]} #{t[1]}"
      @submit.tests_status << {:status => '', :error => []}

      input_file  = @problem.input_file
      output_file = @problem.output_file
      #copy current test's input to input for solution
      test_input_file = "#{@work_dir}/#{(input_file.blank?) ? 'input.txt' : input_file}"
      FileUtils.cp @tests_path+'/'+t[0], test_input_file
      IO.popen("sed -i 's/\r$//' \'#{test_input_file}\'") #Convert Unix endlines to Windows
      #RUN solution      
      ej_ex_version = (File.path(Rails.root).split('/')[2]=='user') ? 'forserver' : 'forlocal'
      command = "\'#{@@system_path}/ejudge-execute-#{ej_ex_version}\' " +
                "--workdir=\'#{@work_dir}\' " +
                "--time-limit-millis=#{(@problem.time_limit*1000).to_i} " +
                "--max-vm-size=#{@problem.memory_limit}M " +
                "--memory-limit " +
                "#{(input_file.blank?)  ? "--stdin=\'#{@work_dir}\'/input.txt"   : nil} " +
                "#{(output_file.blank?) ? "--stdout=\'#{@work_dir}\'/output.txt" : nil} " +
                "\'#{@work_dir}\'/solution"
      pid, stdin, stdout, stderr = Open4::popen4 command
      ignored, open4_status = Process::waitpid2 pid
      verdict = stderr.readlines
      verdict_status = ""
      verdict.each do |line|
        verdict_status = line[8..-1].chomp; break if line.include? "Status: "
      end
      #verdict_status = (ej_ex_version=='forserver') ? verdict[1][8,9].strip : verdict[0][8,9].strip
      if not verdict_status == 'OK'
        @submit.tests_status[i+1][:status] = verdict_status
        @submit.tests_status[i+1][:error]  = verdict

        if @contest.type == 0 || @submit.hidden == true #ACM or submit.HIDDEN
          @submit.status[:status] = verdict_status
          @submit.status[:error]  = verdict
          @submit.status[:test]   = i+1
          @submit.save!
          return
        end

      else
        #puts "!1  #{t[0]} | #{t[1]} | #{verdict}"
        #CHECK(COMPARE answer and test's answer)
        checker_status = self.check(t[0], t[1], (output_file.blank?) ? 'output.txt' : output_file, i+1)
        @submit.tests_status[i+1][:status] = checker_status[:status]
        @submit.tests_status[i+1][:error]  = checker_status[:error]

        #(ACM||HIDDEN) & WRONG
        if (@contest.type == 0 || @submit.hidden == true) && checker_status[:status]!='OK'
          @submit.status[:status] = checker_status[:status]
          @submit.status[:error]  = checker_status[:error]
          @submit.status[:test]   = i+1
          @submit.save!
          return
        end

      end
    end

    if (@contest.type == 0 || @submit.hidden == true)
      @submit.status = {:status=>"AC"}
    else
      @submit.status[:status] = 'OK'  
    end  
    @submit.save!

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

    #skip standing
    return if hidden==true

    #standings
    submit = Submit.find(submit_id)
    problem = submit.problem    
    contest = problem.contest    
    participant = submit.participant


    if contest.type == 1 #IOI
      return if ["CE", "SE"].include? submit.status['status']
      tests_count = submit.tests_status.count - 1
      k = 0
      tests_count.times do |i|
        k += 1 if submit.tests_status[i+1]['status'] == "OK"
      end
      get_percent = lambda {|a, b| (a==0) ? 0 : (b*100)/a }
      participant.a[problem.order] = [participant.a[problem.order], get_percent.call(tests_count, k)].max
      submit.status[:point] = get_percent.call(tests_count, k)
      submit.save!
      participant.summarize
      participant.save!
      return
    end


    #ACM
    if submit.status['status'] == "AC"
      if participant.a[problem.order] <= 0
        participant.a[problem.order] = participant.a[problem.order].abs+1
        participant.penalties[problem.order] += ((Time.now.to_i - participant.contest.time_start.to_i)/60).to_i
        participant.summarize
        participant.save!

        #Contest: last_success
        participant.contest.last_success_submit = submit.id
        participant.contest.save!
      end
    elsif ['WA', 'TL', 'RT', 'PT', 'SE'].include? submit.status['status']
      if participant.a[problem.order] <= 0
        participant.a[problem.order] -= 1
        participant.penalties[problem.order] += 20
        participant.summarize
        participant.save!
      end
    end
  end
end
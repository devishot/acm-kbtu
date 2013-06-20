require 'fileutils'
require 'open4'
require 'resque'

class TestCheckerJob
  @queue = :test_checker

  def self.perform(problem_id)
    problem = Problem.find(problem_id)
    status = {:status => 'OK', :error => []}

    Dir.entries(problem.tests_dir).sort[2..-1].each_slice(2) do |t|
      command = "\'#{problem.checker_dir}/checker\' \'#{problem.tests_dir+'/'+t[0]}\' \'#{problem.tests_dir+'/'+t[1]}\' \'#{problem.tests_dir+'/'+t[1]}\'"
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
        if not std_err.nil?
          if std_err.kind_of? String
            status[:error] << std_err
          elsif std_err.kind_of? Array            
            std_err.each {|x| status[:error] << x}
          end
        end
        break;
      end
    end

    if not status[:status] == 'OK'
      #delete checker
      problem.checker_path = ''
      problem.checker_mode = 0
      FileUtils.rm_rf problem.checker_dir
    else
      problem.checker_mode = 2
    end

    problem.save!
  end

end
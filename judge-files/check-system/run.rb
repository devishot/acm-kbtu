require 'moped'
require "fileutils"
require "open4"
require 'date'

session = Moped::Session.new(["127.0.0.1:27017"])
session.use :acm_kbtu_development

session.with(safe: true) do |_session|
  submits = _session[:submits].find
  system_path = '/home/devishot/Documents/Programming/Rails Projects/acm-kbtu/judge-files/check-system'
  folder = "#{system_path}/work/"

  submits.each do |submit|
    #next if submit.to_a[1][1]!=""
    ##puts _session[:problems].find(_id: submit.to_a[3][1]).find.first
    ##puts "\n"

    #//copy submit's sourcecode in file src_path
    FileUtils.cp submit.to_a[5][1], "#{folder}1.cpp" #.to_a() <- convert hash to matrix [][0..1];

    #//compile file src_path and put CEerror
    pid, stdin, stdout, stderr = Open4::popen4 "g++ ./work/1.cpp -o ./work/1.exe"
    compile_err = stderr.gets #we need to save, it will changed
    if compile_err.nil?
      submit.update("status" => "OK")
      submit.update("status_full" => "")
    else
      submit.update("status" => "CE")
      submit.update("status_full" => compile_err)
    end


    #//get tests
    tests_path = _session[:problems].find(_id: submit.to_a[3][1]).find.first.to_a[6][1]
    
    Dir.entries(tests_path).sort.each_slice(2) do |t|
      next if t[0] == '.'
      FileUtils.cp tests_path+'/'+t[0], "work/input.txt" #copy current test's input to work/input.txt file
      #//RUN
      pid, stdin, stdout, stderr = Open4::popen4 "./ejudge-execute --time-limit=2 --stdin=work/input.txt --stdout=work/output.txt work/1.exe"

      verdict = stderr.gets
      verdict = verdict[8,9].strip

      if verdict == 'OK' #//puts "runs correctly"
        #//CHECK(COMPARE)
        pid, stdin, stdout, stderr = Open4::popen4 "checkers/cmp_file \'#{tests_path}/#{t[0]}\' work/output.txt \'#{tests_path}/#{t[1]}\'"
        ignored, status = Process::waitpid2 pid

        std_out = stdout.gets
        std_err = stderr.gets

        submit.update("status" => case status.exitstatus
          when 0; "AC"
          when 4; "PE"
          when 5; "WA"
          else "SE" end)
        submit.update("status_full" => "")
      else
        submit.update("status" => verdict)  #// TL or other errors
        submit.update("status_full" => "")
      end  
    end


    #//save changes
    submit_id = Moped::BSON::ObjectId.from_string(submit.to_a[0][1])
    _session[:submits].find(_id: submit_id).update(submit)
  end
end
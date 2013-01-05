require 'moped'
require "fileutils"
require "open4"
require 'date'

session = Moped::Session.new(["127.0.0.1:27017"])
session.use :acm_kbtu_development

session.with(safe: true) do |_session|
  submits = _session[:submits].find
  src_path = "/home/devishot/Documents/Programming/Rails Projects/acm-kbtu/public/check-system/1.cpp"

  submits.each do |submit|
    #//copy submit's sourcecode in file src_path
    FileUtils.cp submit.to_a[5][1], src_path #.to_a() <- convert hash to matrix [][0..1];

    #//compile file src_path and put CEerror
    pid, stdin, stdout, stderr = Open4::popen4 "g++ 1.cpp -o 1.o"
    compile_err = stderr.gets #we need to save, it will changed
    if compile_err.nil?
      submit.update("status" => "OK")
    else
      submit.update("status" => "CE")
      submit.update("status_full" => compile_err)
    end

    #//save changes
    submit_id = Moped::BSON::ObjectId.from_string(submit.to_a[0][1])
    _session[:submits].find(_id: submit_id).update(submit)
  end
end
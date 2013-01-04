require 'moped'
require "fileutils"
require "open4"

session = Moped::Session.new(["127.0.0.1:27017"])
session.use :acm_kbtu_development


submits = session[:submits].find
puts "There are #{submits.count} records. Here they are:"
submits.find.each { |submit|
  submit.update(status: "CHecking")
  path = submit.to_a[5][1]  #.to_a() <- convert hash to matrix [][0..1];
  #puts path
  #puts submit.inspect
}


src_path = "/home/devishot/Documents/Programming/Rails Projects/acm-kbtu/public/check-system/1.cpp"
FileUtils.cp (submits.find.first).to_a[5][1], src_path


pid, stdin, stdout, stderr = Open4::popen4 "g++ 1.cpp -o 1.o"
compile_err = stderr.gets #we need save, it will be changed

if compile_err.nil?
  puts "compiled"
  submits.find.first.update({:status => "Ok"})
else
  puts "CE\n#{compile_err}"
  submits.find.first.update({:status => "CE"})
end

puts session[:submits].find(_id: "50e703c2bb5fcb190a000004").count
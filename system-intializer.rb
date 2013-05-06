require "open4"


#compile checkers
root = "judge-files/check-system"
testlib_path    = "#{root}/include/"
checkers_source = "#{root}/sources/checkers/"
checkers_path   = "#{root}/checkers/"

Dir.entries(checkers_source).each do |i|
  next if not File.extname(i) == ".cpp"
  command = "g++ -I #{testlib_path} #{checkers_source+i} -o #{checkers_path+File.basename(i, ".*")}"
  puts command
  pid, stdin, stdout, stderr = Open4::popen4 command
  puts stderr.readlines, stdout.readlines
  ignored, open4_status = Process::waitpid2 pid
end

puts "Checkers compiled"
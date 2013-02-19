module Compiler
  def Compiler.compile(ufile)
    if File.extname(ufile) == ".cpp"
      pid, stdin, stdout, stderr = 
        Open4::popen4 "g++ \'#{File.path(ufile)}\' -o \'#{File.dirname(ufile)}/checker.exe\'"
      compile_err = stderr.readlines #we need to save, it will changed
    elsif File.extname(ufile) == ".pas"
      pid, stdin, stdout, stderr = 
        Open4::popen4 "fpc \'#{File.path(ufile)}\' -o\'#{File.dirname(ufile)}/checker.exe\'"
      #puts "#{pid} #{stdout.readlines.inspect} #{stderr.readlines.inspect}"
      compile_err = stderr.readlines #we need to save, it will changed
      compile_err.each_with_index do |value,index|
        #value.include? "warning:"
      end
    else
      compile_err = ["file extension not supported."]
    end
      

    if compile_err.blank?
      return {'status' => 'OK'}
    else
      return {'status' => 'CE', 'error' => compile_err}
    end
  end
end
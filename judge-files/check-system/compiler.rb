module Compiler
  def Compiler.compile(ufile)
    pid, stdin, stdout, stderr = Open4::popen4 "g++ \'#{File.path(ufile)}\' -o \'#{File.dirname(ufile)}/1.exe\'"
    compile_err = stderr.gets #we need to save, it will changed

    raise "#{compile_err}"

    if compile_err.blank?
      return {'status' => 'OK'}
    else
      return {'status' => 'CE', 'error' => compile_err}
    end
  end
end
module Compiler
  def Compiler.compile(ufile)
    pid, stdin, stdout, stderr = Open4::popen4 "g++ \'#{File.path(ufile)}\' -o \'#{File.dirname(ufile)}/checker.exe\'"
    compile_err = stderr.readlines #we need to save, it will changed

    if compile_err.blank?
      return {'status' => 'OK'}
    else
      return {'status' => 'CE', 'error' => compile_err}
    end
  end
end
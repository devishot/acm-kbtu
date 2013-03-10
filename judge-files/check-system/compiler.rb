module Compiler

  def Compiler.compile(ufile, checker=false)
    include_path = "#{Rails.root}/judge-files/check-system/include"
    lib_path     = "#{Rails.root}/judge-files/check-system/lib"

    if File.extname(ufile) == ".cpp"
      if checker == true #IF it is checker THEN include testlib.[h, pas]
        command = "g++ -I \'#{include_path}\' \'#{File.path(ufile)}\' -o \'#{File.dirname(ufile)}/checker\'"
      else
        command = "g++ \'#{File.path(ufile)}\' -o \'#{File.dirname(ufile)}/#{File.basename(ufile, '.*')}\'"
      end
      #puts command
      pid, stdin, stdout, stderr = Open4::popen4 command
      compile_err = stderr.readlines #we need to save, it will changed

    elsif File.extname(ufile) == ".pas" || File.extname(ufile) == ".dpr"
      if checker == true #IF it is checker THEN include testlib.[h, pas]
        command = "fpc -S2 -Fu\'#{include_path}\' \'#{File.path(ufile)}\' -o\'#{File.dirname(ufile)}/checker\'"
      else
        command = "fpc \'#{File.path(ufile)}\' -o\'#{File.dirname(ufile)}/#{File.basename(ufile, '.*')}\'"
      end
      pid, stdin, stdout, stderr = Open4::popen4 command
      compile_err = stderr.readlines  #we need to save, it will changed
      compile_out = stdout.readlines  #there is only warnings, so stupid fpc
      #two example of fpc compilation errors: http://pastie.org/6222145
      if compile_out.include? "Fatal: Compilation aborted\n"
        compile_err = compile_out[4..-2]  #we ingore warnings and save here compile errors
      else
        compile_err = [] # .pas successfuly compiled
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
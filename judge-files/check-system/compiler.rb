require 'fileutils'
require 'open4'
module Compiler

  #   compile(source file path, destination file, checker=false)
  def Compiler.compile(src_code, dest_file, checker=false)
    include_path = "#{Rails.root}/judge-files/check-system/include"

    #check source_code
    src_code = File.expand_path(src_code)
    src_code_ext = File.extname(src_code)
    if not File.exist?(src_code)
      return {'status' => 'SE', 
              'error' => ["there is no \"#{src_code}\""]}
    elsif File.directory?(src_code)
      return {'status' => 'SE', 
              'error' => ["\"#{src_code}\" is not file, it is directory"]}
    end

    #check destination directory
    dest_file = File.expand_path(dest_file)
    dest_dir = File.dirname(dest_file)
    FileUtils.mkdir_p dest_dir if not File.exist?(dest_dir)
    if File.directory?(dest_file)
      return {'status' => 'SE', 
              'error' => ["\"#{dest_file}\" is directory"]}
    end

    #compile source in destination directory as dest_name
    #IF checker THEN include testlib.[h, pas]
    if src_code_ext == ".cpp"
      params = (checker == true) ? "-I \'#{include_path}\'" : nil
      command = "g++ #{params} \'#{src_code}\' -o \'#{dest_file}\'"
      #run
      pid, stdin, stdout, stderr = Open4::popen4 command
      ignored, open4_status = Process::waitpid2 pid
      #get error
      compile_err = stderr.readlines #we need to save, it will changed
      #puts "#{stdout.readlines} | #{compile_err} | #{open4_status}"

    elsif src_code_ext == ".pas" || src_code_ext == ".dpr"
      params = (checker == true) ? "-S2 -Fu\'#{include_path}\'" : nil
      command = "fpc #{params} \'#{src_code}\' -o\'#{dest_file}\'"
      #run
      pid, stdin, stdout, stderr = Open4::popen4 command
      ignored, open4_status = Process::waitpid2 pid
      #get and parse error
      compile_err = stderr.readlines  #we need to save, it will changed
      compile_out = stdout.readlines #there is only warnings, so stupid FPC
      #two example of fpc compilation errors: http://pastie.org/6222145
      if compile_out.include? "Fatal: Compilation aborted\n"
        compile_err = compile_out[4..-2]  #we ingore warnings and save here compile errors
      else
        compile_err = [] # .pas successfuly compiled
      end

    else
      open4_status = 1
      compile_err = ["file extension not supported."]
    end
  

    if open4_status.nil?
      return {'status' => 'SE'}
    elsif open4_status == 0
      return {'status' => 'OK'}
    else
      return {'status' => 'CE', 'error' => compile_err}
    end

  end
end
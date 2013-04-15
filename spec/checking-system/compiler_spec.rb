require "spec_helper"
require "#{Rails.root}/judge-files/check-system/compiler"

tmp_dir  = "#{Rails.root}/spec/tmpFiles"

describe Compiler do
  describe "Check source and destination files:" do
    it 'return SE, if #source_code is not file' do
      src  = "#{tmp_dir}/a."
      dest = "#{tmp_dir}/solution"
      status = Compiler.compile(src, dest)
      status['status'].should eq 'SE'
      status['error'][0].should match "there is no"
    end
    it 'return SE, if #source_code is folder' do
      src  = "#{tmp_dir}"
      dest = "#{tmp_dir}/solution"
      status = Compiler.compile(src, dest)
      status['status'].should eq 'SE'
      status['error'][0].should match "is not file, it is directory"
    end
    it 'return SE, if #destination_file is folder' do
      src  = "#{tmp_dir}/ok.cpp"
      dest = "#{tmp_dir}/"
      status = Compiler.compile(src, dest)
      status['status'].should eq 'SE'
      status['error'][0].should match "is directory"
    end
    it 'return CE, if #source_code not supported' do
      src  = "#{tmp_dir}/unsupported.py"
      dest = "#{tmp_dir}/solution"
      status = Compiler.compile(src, dest)
      status['status'].should eq 'CE'
      status['error'][0].should match "file extension not supported."
    end    
  end

  describe "Compile C++" do
    it 'with OK' do
    	src  = "#{tmp_dir}/ok.cpp"
    	dest = "#{tmp_dir}/solution"
    	Compiler.compile(src, dest)['status'].should eq 'OK'
      #after
      FileUtils.rm "#{tmp_dir}/solution"      
    end
    it 'with CE' do
      src  = "#{tmp_dir}/ce.cpp"
      dest = "#{tmp_dir}/solution"
      Compiler.compile(src, dest)['status'].should eq 'CE'
    end
  end

  describe "Compile Pascal(FPC)" do
    it 'with OK' do
      src  = "#{tmp_dir}/ok.pas"
      dest = "#{tmp_dir}/solution"
      Compiler.compile(src, dest)['status'].should eq 'OK'
      #after
      FileUtils.rm "#{tmp_dir}/solution"      
    end
    it 'Checker with OK' do      
      src  = "#{tmp_dir}/checker.dpr"
      dest = "#{tmp_dir}/checker"
      Compiler.compile(src, dest, true)['status'].should eq 'OK'
      #after
      FileUtils.rm "#{tmp_dir}/checker"
    end
    it 'with CE' do
      src  = "#{tmp_dir}/ce.pas"
      dest = "#{tmp_dir}/solution"
      Compiler.compile(src, dest)['status'].should eq 'CE'
    end
  end  
end
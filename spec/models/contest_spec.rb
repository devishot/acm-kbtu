require "spec_helper"

tmp_dir  = "#{Rails.root}/spec/tmpFiles"

describe Contest do
  before do
    #create contest
    @contest = Contest.new()
    @contest.save
  end

  describe "put_problems method should" do
    it "got error archive extention not supported" do
      params = {:problem => {}, :tests_archive => ''}
      archive = ActionDispatch::Http::UploadedFile.new({
          :filename => "archive.SU*K", 
          :tempfile => File.new(tmp_dir+'/PROBLEMS.zip')
      })
      status = @contest.put_problems(archive)
      status[:error].should include("archive not supported")
    end
    it "got error json parsed with error" do
      params = {:problem => {}, :tests_archive => ''}
      archive = ActionDispatch::Http::UploadedFile.new({
          :filename => "archive.zip", 
          :tempfile => File.new(tmp_dir+'/PROBLEMS JSON with error.zip')
      })
      status = @contest.put_problems(archive)
      status[:error].should include("JSON Parsing error:")
    end
    it "got error json problems not found" do
      params = {:problem => {}, :tests_archive => ''}
      archive = ActionDispatch::Http::UploadedFile.new({
          :filename => "archive.zip", 
          :tempfile => File.new(tmp_dir+'/PROBLEMS JSON without problems.zip')
      })
      status = @contest.put_problems(archive)
      status[:error].should include("JSON: Problem 'a' as #1 not found")
      status[:error].should include("JSON: Problem '1' as #1 not found")
    end
    it "put setting, got error tests not found" do
      params = {:problem => {}, :tests_archive => ''}
      archive = ActionDispatch::Http::UploadedFile.new({
          :filename => "archive.zip", 
          :tempfile => File.new(tmp_dir+'/PROBLEM without tests.zip')
      })
      status = @contest.put_problems(archive)

      template = @contest.problems.find_by(order: 0)
      template.time_limit.should == 2
      template.memory_limit.should == 256
      template.input_file.should == nil
      template.output_file.should == nil
      #1
      problem1 = @contest.problems.find_by(order: 1)
      problem1.time_limit.should == 3
      problem1.memory_limit.should == 99
      problem1.input_file.should == 'k.in'
      problem1.output_file.should == 'k.out'
      status[:error].should include("Problem 1: there is no Tests")
    end    
    it "put problems without errors" do
      params = {:problem => {}, :tests_archive => ''}
      archive = ActionDispatch::Http::UploadedFile.new({
          :filename => "archive.zip", 
          :tempfile => File.new(tmp_dir+'/PROBLEMS.zip')
      })
      status = @contest.put_problems(archive)

      template = @contest.problems.find_by(order: 0)
      template.time_limit.should    == 2
      template.memory_limit.should  == 666
      template.input_file.should    == nil
      template.output_file.should   == nil
      template.checker_mode.should  == 2
      File.basename(template.checker_path).should == "Template_check_DEV.dpr"
      File.basename(template.statement['file_link']).should == "0_problems.pdf"
      #1
      problem1=@contest.problems.find_by(order: 1)
      problem1.time_limit.should    == 3
      problem1.memory_limit.should  == 99
      problem1.input_file.should    == 'k.in'
      problem1.output_file.should   == 'k.out'
      problem1.checker_mode.should  == 2
      File.basename(problem1.checker_path).should == "a_check_K.dpr"
      #2
      problem2=@contest.problems.find_by(order: 2)
      problem2.time_limit.should    == 2
      problem2.memory_limit.should  == 666
      problem2.input_file.should    == 'm.in'
      problem2.output_file.should   == 'm.out'
      problem2.checker_mode.should  == 2
      File.basename(problem2.checker_path).should == "b_check_M.dpr"
      #3
      problem3=@contest.problems.find_by(order: 3)
      problem3.time_limit.should    == 2
      problem3.memory_limit.should  == 666
      problem3.input_file.should    == 'o.in'
      problem3.output_file.should   == 'o.out'
      problem3.checker_mode.should  == 2
      File.basename(problem3.checker_path).should == "c_check_O.dpr"
      #errors
      status[:error].should be_empty
    end

  end
end
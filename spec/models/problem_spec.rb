require "spec_helper"

tmp_dir  = "#{Rails.root}/spec/tmpFiles"

describe Problem do
  before do
    #create contest
    @contest = Contest.new()
    @contest.save
    #create problem
    @contest.upd_problems_count(1)
    @problem = @contest.problems.find_by(order: 1)
    @problem.save
  end

  describe "put_problem method:" do
    describe "put tests" do
      it "should be putted" do
        params = {:problem => {}, :tests_archive => ''}
        params[:tests_archive] = ActionDispatch::Http::UploadedFile.new({
            :filename => "tests_for_ok_cpp.tgz", 
            :tempfile => File.new(tmp_dir+'/tests.tgz')})
        status = @problem.put_problem(params)
        status[:notice].should include("Tests uploaded")

        status[:notice].should include("Problem updated")
      end
      it "should got SE, there is only .. files" do
        params = {:problem => {}, :tests_archive => ''}
        params[:tests_archive] = ActionDispatch::Http::UploadedFile.new({
            :filename => "tests_one_test_deleted.tgz", 
            :tempfile => File.new(tmp_dir+'/tests_one_test_deleted.tgz')})
        status = @problem.put_problem(params)
        status[:alert].should include("Tests not uploaded:")
        status[:alert].should include("---there is only 59 files")

        status[:notice].should include("Problem updated")        
      end
      it "should got SE, test .. is incorrect" do
        params = {:problem => {}, :tests_archive => ''}
        params[:tests_archive] = ActionDispatch::Http::UploadedFile.new({
            :filename => "tests_one_pair_differen.tgz", 
            :tempfile => File.new(tmp_dir+'/tests_one_pair_differen.tgz')})
        status = @problem.put_problem(params)
        status[:alert].should include("Tests not uploaded:")
        status[:alert].should include("---test | 00.in : 001.in | is incorrect")

        status[:notice].should include("Problem updated")
      end      
    end

    describe "put checker" do
      it "should be putted" do
        params = {:problem => {}, :uploaded_checker => ''}
        params[:problem][:uploaded_checker] = ActionDispatch::Http::UploadedFile.new({
            :filename => "checker_for_ok_cpp.dpr", 
            :tempfile => File.new(tmp_dir+'/checker.dpr')})
        status = @problem.put_problem(params)
        status[:notice].should include("Checker compiled")

        status[:notice].should include("Problem updated")        
      end
      it "should got CE" do
        params = {:problem => {}, :uploaded_checker => ''}
        params[:problem][:uploaded_checker] = ActionDispatch::Http::UploadedFile.new({
            :filename => "file_with_errors.cpp", 
            :tempfile => File.new(tmp_dir+'/ce.cpp')})
        status = @problem.put_problem(params)
        status[:alert].should include("Checker was not compiled(CE):")

        status[:notice].should include("Problem updated")
      end
    end

    describe "put solution" do
      it "should got CE" do
        params = {:problem => {}, :tests_archive => ''}
        params[:tests_archive] = ActionDispatch::Http::UploadedFile.new({
            :filename => "tests_for_ok_cpp.tgz", 
            :tempfile => File.new(tmp_dir+'/tests.tgz')})

        params[:problem][:uploaded_checker] = ActionDispatch::Http::UploadedFile.new({
            :filename => "checker_for_ok_cpp.dpr", 
            :tempfile => File.new(tmp_dir+'/checker.dpr')})

        params[:solution_file] = ActionDispatch::Http::UploadedFile.new({
            :filename => "ce.cpp", 
            :tempfile => File.new(tmp_dir+'/ce.cpp')})

        status = @problem.put_problem(params)
        status[:notice].should include("Tests uploaded")
        status[:notice].should include("Checker compiled")
        status[:alert].should  include("solution is incorrect, got a CE")

        status[:notice].should include("Problem updated")
      end
      it "should be putted" do
        params = {:problem => {}, :tests_archive => ''}
        params[:tests_archive] = ActionDispatch::Http::UploadedFile.new({
            :filename => "tests_for_ok_cpp.tgz",
            :tempfile => File.new(tmp_dir+'/tests.tgz')})

        params[:problem][:uploaded_checker] = ActionDispatch::Http::UploadedFile.new({
            :filename => "checker_for_ok_cpp.dpr", 
            :tempfile => File.new(tmp_dir+'/checker.dpr')})

        params[:solution_file] = ActionDispatch::Http::UploadedFile.new({
            :filename => "ok.cpp",
            :tempfile => File.new(tmp_dir+'/ok.cpp')})

        @problem.input_file  = 'o.in'
        @problem.output_file = 'o.out'
        @problem.save
        status = @problem.put_problem(params)
        status[:notice].should include("Tests uploaded")
        status[:notice].should include("Checker compiled")
        status[:notice].should include("solution added, problem checked")
        status[:notice].should include("Problem updated")
      end
      it "should be REchecked" do
        params = {:problem => {}, :tests_archive => ''}
        params[:tests_archive] = ActionDispatch::Http::UploadedFile.new({
            :filename => "tests_for_ok_cpp.tgz",
            :tempfile => File.new(tmp_dir+'/tests.tgz')})

        params[:problem][:uploaded_checker] = ActionDispatch::Http::UploadedFile.new({
            :filename => "checker_for_ok_cpp.dpr", 
            :tempfile => File.new(tmp_dir+'/checker.dpr')})

        params[:solution_file] = ActionDispatch::Http::UploadedFile.new({
            :filename => "ok.cpp",
            :tempfile => File.new(tmp_dir+'/ok.cpp')})

        params[:sex] = 'SEX'

        @problem.input_file  = 'o.in'
        @problem.output_file = 'o.out'
        @problem.save
        status = @problem.put_problem(params)
        status[:notice].should include("Tests uploaded")
        status[:notice].should include("Checker compiled")
        status[:notice].should include("solution added, problem checked")
        ##REcheck solution
        params.delete(:solution_file)
        params.delete(:tests_archive)
        status = @problem.put_problem(params)
        status[:notice].should include("problem REchecked")

        status[:notice].should include("Problem updated")
      end
    end

    it "put Contest's problems via one archive"
  end

  after do
    @contest.destroy
  end
end
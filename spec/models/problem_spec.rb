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

  describe "put_problem" do
    it "put tests" do
      params = {:problem => {}, :tests_archive => ''}
      params[:tests_archive] = ActionDispatch::Http::UploadedFile.new({
          :filename => "tests_for_ok_cpp.tgz", 
          :tempfile => File.new(tmp_dir+'/tests.tgz')})
      status = @problem.put_problem(params)
      #raise status.inspect
      status[:notice].should include("Tests uploaded")
    end
    it "put Contest's problems via one archive"
  end

  after do
    @contest.destroy
  end  
end
require "spec_helper"

tmp_dir  = "#{Rails.root}/spec/tmpFiles"

describe Tester do
  before(:all) do
    @contest = Contest.new()
    @contest.save
    #create problem with tests
    @contest.upd_problems_count(1)
    @problem = @contest.problems.find_by(order: 1)
    FileUtils.cp_r "#{tmp_dir}/tests/", @problem.tests_dir
    #create submit
    @submit = Submit.new({:problem => @problem})
    @submit.save    
  end

  describe 'system checkers' do
    before do
      #put other tests
      FileUtils.rmdir "#{tmp_dir}/tests/"
      FileUtils.cp_r "#{tmp_dir}/tests2/", @problem.tests_dir
      FileUtils.mv "#{tmp_dir}/tests2/", "#{tmp_dir}/tests/"
      #put source code
      @submit.file_sourcecode_path = "#{tmp_dir}/ok.cpp"
      @submit.save      
    end
    it 'should return AC' do
      Tester.perform(submit.id, true)
    end    
  end

  xit 'should return AC' do
    @submit.file_sourcecode_path = "#{tmp_dir}/ok.cpp"
    @submit.save
    Resque.enqueue(Tester, submit.id, true)
    status = Compiler.compile(src, dest)
    status['status'].should eq 'SE'
    status['error'][0].should match "there is no"
  end

  after(:all) do
    @contest.destroy
  end  
end
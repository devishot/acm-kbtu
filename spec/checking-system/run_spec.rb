require "spec_helper"
#require "#{Rails.root}/judge-files/check-system/run"

tmp_dir  = "#{Rails.root}/spec/tmpFiles"

describe Tester do
  before do
    @contest = Contest.new()
    @contest.save
    #create problem and put tests
    @contest.upd_problems_count(1)
    @problem = @contest.problems.find_by(order: 1)
    @problem.checker_mode = 0
    FileUtils.mkdir_p @problem.tests_dir
    FileUtils.cp_r "#{tmp_dir}/tests/.", @problem.tests_dir
    #create submit
    @submit = Submit.new({
              :problem => @problem, 
              :file_sourcecode_path => "#{tmp_dir}/ok.cpp"})
    @submit.save    
  end

  xit 'should return AC' do
    Tester.perform(@submit.id, true)
    @submit.reload
    @submit.status['status'].should == 'AC'
  end  

  it 'should return SE, if source code not found' do
    @submit.file_sourcecode_path = "#{tmp_dir}/not.found"
    @submit.save
    Tester.perform(@submit.id, true)
    @submit.reload
    @submit.status['status'].should == 'SE'
    @submit.status['error'][0].should match 'source code not found'
  end

  it 'should return SE, if tests not found' do
    FileUtils.remove_dir @problem.tests_dir
    Tester.perform(@submit.id, true)
    @submit.reload
    @submit.status['status'].should == 'SE'
    @submit.status['error'][0].should match 'tests not found'
  end

  it 'should return CE' do
    @submit.file_sourcecode_path = "#{tmp_dir}/ce.cpp"
    @submit.save
    Tester.perform(@submit.id, true)
    @submit.reload
    @submit.status['status'].should == 'CE'
  end

  describe 'check checkers' do
    it 'should return SE, if own checker not found' do
      #set to own checker which doesn't exist
      @problem.checker_mode = 2
      @problem.save
      Tester.perform(@submit.id, true)
      @submit.reload      
      @submit.status["status"].should == 'SE'
      @submit.status['error'][0].should match 'checker not found'
    end
    xit 'should return AC' do
      #put other tests
      FileUtils.rmdir @problem.tests_dir
      FileUtils.cp_r  "#{tmp_dir}/tests2/.", @problem.tests_dir
      #put source code
      @submit.file_sourcecode_path = "#{tmp_dir}/ok2.cpp"
      @submit.save
      Tester.perform(@submit.id, true)
      @submit.reload
      @submit.status['status'].should == 'AC'
    end
  end

  after do
    @contest.destroy
  end
end
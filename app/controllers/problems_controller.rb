class ProblemsController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :find_contest, :except => [:index, :update, :update_statement]
  before_filter :find_problem, :only => [:show, :edit, :edit_statement, :download_statement]
  before_filter :find_contest_problem, :only => [:update, :update_statement]
  load_and_authorize_resource

  rescue_from Mongoid::Errors::DocumentNotFound do |exception|
    redirect_to contest_path(params[:id]), :alert => "Problem ##{params[:problem]} not found"
  end


  # GET /contests/:id/problems
  def index
    @navpill = 2
    redirect_to contest_path(params[:id])+'/1'
  end

  # GET /contests/:id/:problem
  def show
    #@contest = Contest.find_by(path: params[:id])
    #@problem = @contest.problems.find_by(order: params[:problem])
    if @problem.order == 0
      redirect_to contest_path(@contest.path)
      return
    end

    @submit = Submit.new()
    @submit.problem = @problem

    if current_user == @contest.user || current_user.admin?
      #nothing
    elsif not current_user.participate?(@contest)  then
      redirect_to contest_path(@contest.path), alert: 'Please, register to participate.'
      return
    elsif not @contest.started?
      redirect_to contest_path(@contest.path), alert: 'Contest does not start'
      return
    else
      participant = current_user.participants.find_by(contest: @contest)
      @submit.participant = participant
      @submissions = participant.submits.where(problem: @problem)
    end

    @navpill = 2
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /contests/:id/:problem/edit
  def edit
    #@contest = Contest.find_by(path: params[:id])
    #@problem = @contest.problems.find_by(order: params[:problem])
  end

  # GET /contests/:id/:problem/edit_statement
  def edit_statement
    #@contest = Contest.find_by(path: params[:id])
    #@problem = @contest.problems.find_by(order: params[:problem])
    
    redirect_to contest_control_problems_path(@contest.path) if @problem.order==0
  end

  # PUT /contests/:id/:problem
  def update
    #@contest = Contest.find(params[:contest_id])
    #@problem = @contest.problems.find_by(order: params[:problem_order])
    flash[:notice] = []
    flash[:alert]  = []    

    if not params[:statement].nil?
      @problem.put_statement(params[:statement])
    end

    #//put problems if upload && @problem.order==0
    if not params[:problems].nil?
      @problems_status = @contest.put_problems(params[:problems]) 
      flash[:alert] = flash[:alert] + @problems_status['error']
    end
    #//put problem's tests if uploaded
    @problem.put_tests(params[:tests_archive]) if not params[:tests_archive].nil?
    #//put checker if uploaded
    if not params[:problem][:uploaded_checker].nil?
      @checker_status = @problem.put_checker(params[:problem][:uploaded_checker])
      puts @checker_status['status']
      puts @checker_status['error']      
      if @checker_status['status'] == 'OK'
        flash[:notice].push('Checker compiled.')
        flash[:notice].push('')
        params[:problem][:checker_mode] = '2'

      elsif @checker_status['status'] == 'CE'
        flash[:alert].push('Checker was not compiled.')
        flash[:alert].concat(@checker_status['error']) #it is array
        flash[:alert].push('')

      elsif @checker_status['status'] == 'NW'
        flash[:alert].push('Checker was not work.')
        flash[:alert].concat(@checker_status['error']) #it is array
        flash[:alert].push('')        
      end
      params[:problem].delete(:uploaded_checker)
    end
    #//set template's checker if used
    if not params[:problem][:checker_mode]==@problem.checker_mode
      if params[:problem][:checker_mode]=='2' && @problem.checker_path.blank?
        params[:problem][:checker_mode] = (@problem.template.checker_mode==2) ? '1' : '0'
      end
    end
    #//check solution file CHECK TESTS AND CHECKER
    if not params[:solution_file].nil?
      @problem.check_problem(params[:solution_file])
    end

    respond_to do |format|
      if @problem.update_attributes(params[:problem])
        format.html { redirect_to contest_control_problems_path(@contest.path, tab:@problem.order)}
        flash[:notice].push('Problem properties was successfully updated.');
      else
        format.html { redirect_to contest_control_problems_path(@contest.path, tab:@problem.order)}
        flash[:alert].push('Problem properties was not updated.')
      end
      #update problems if template(@problem.order==0) updated
      @contest.upd_problems_template if @problem.order==0 
    end
  end    

  # PUT /contests/:id/:problem/update_statement
  def update_statement
    #@contest = Contest.find(params[:contest_id])
    #@problem = @contest.problems.find_by(order: params[:problem_order])
    inputs = []
    outputs = []
    3.times do |i|
      inputs << params["input#{i}"]
      outputs << params["output#{i}"]
    end
    @problem.statement = {:title => params[:title], 
                          :text => params[:text], 
                          :inputs => inputs, 
                          :outputs => outputs }

    #put statement file
    if not params[:statement].nil?
      @problem.put_statement(params[:statement])
    end                          

    respond_to do |format|
      if @problem.save
        format.html { redirect_to contest_problem_path(@contest.path, @problem.order), 
          notice: 'Problem\'s statement was successfully updated.' }
      else
        format.html { redirect_to contest_problem_path(@contest.path, @problem.order), 
          alert:  'ERROR: Problem\'s statement was not updated.' }
      end
    end
  end

  # GET /contests/:id/:problem/statement
  def download_statement
    #@contest = Contest.find(params[:contest_id])
    #@problem = @contest.problems.find_by(order: params[:problem_order])
    statement = @problem.statement['file_link']
    if statement.blank?
      redirect_to contest_problem_path(@contest.path, @problem.order),
                  alert: 'not uploaded yet'
    else    
      send_file(statement)
    end
  end


private
  def find_contest
    @contest = Contest.find_by(path: params[:id])
  end

  def find_problem
    @problem = @contest.problems.find_by(order: params[:problem])
  end

  def find_contest_problem
    @contest = Contest.find(params[:contest_id])
    @problem = @contest.problems.find_by(order: params[:problem_order]) 
  end

  # # GET /problems/new
  # # GET /problems/new.json
  # def new
  #   @problem = Problem.new

  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.json { render json: @problem }
  #   end
  # end

  # POST /problems
  # POST /problems.json
  # def create
  #   @problem = Problem.new(params[:problem])

  #   respond_to do |format|
  #     if @problem.save
  #       format.html { redirect_to @problem, notice: 'Problem was successfully created.' }
  #       format.json { render json: @problem, status: :created, location: @problem }
  #     else
  #       format.html { render action: "new" }
  #       format.json { render json: @problem.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # DELETE /problems/1
  # # DELETE /problems/1.json
  # def destroy
  #   @problem = Problem.find(params[:id])
  #   @problem.destroy

  #   respond_to do |format|
  #     format.html { redirect_to problems_url }
  #     format.json { head :no_content }
  #   end
  # end

end

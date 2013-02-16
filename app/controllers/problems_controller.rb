class ProblemsController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :find_contest, :except => [:index, :update, :update_statement]
  before_filter :find_problem, :only => [:show, :edit, :edit_statement]
  before_filter :find_contest_problem, :only => [:update, :update_statement]
  load_and_authorize_resource


  # GET /contests/:id/problems
  def index
    @navpill = 1
    redirect_to "/contests/#{params[:id]}/1"
  end

  # GET /contests/:id/:problem
  def show
    #@contest = Contest.find_by(path: params[:id])
    #@problem = @contest.problems.find_by(order: params[:problem])
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

    @navpill = 1
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
  end

  # PUT /contests/:id/:problem
  def update
    #@contest = Contest.find(params[:contest_id])
    #@problem = @contest.problems.find_by(order: params[:problem_order])
    if not params[:problem][:uploaded_checker].nil?
      @checker_status = @problem.get_checker(params[:problem][:uploaded_checker])
    end
    
    respond_to do |format|
      flash[:notice] = flash[:alert] = []
      if @checker_status['status'] == 'OK'
        flash[:notice].push('Checker compiled')
      else
        flash[:alert].concat(@checker_status['error']) #it is array
      end

      if @problem.update_attributes(params[:problem].except(:uploaded_checker))
        format.html { redirect_to contest_path(@contest.path)+"/#{@problem.order}/edit", 
          flash[:notice]=>'Problem properties was successfully updated.'
        }
      else
        format.html { redirect_to contest_path(@contest.path)+"/#{@problem.order}/edit",
          flash[:alert].push('Problem properties was not updated.')}
      end
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
    #and set tests_path if uploaded
    @problem.unzip(params[:archive]) if !params[:archive].nil?
    
    respond_to do |format|
      if @problem.save
        format.html { redirect_to contest_path(@contest.path)+"/#{@problem.order}", 
          notice: 'Problem\'s statement was successfully updated.' }
      else
        format.html { redirect_to contest_path(@contest.path)+"/#{@problem.order}", 
          alert: 'ERROR: Problem\'s statement was not updated.' }
      end
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

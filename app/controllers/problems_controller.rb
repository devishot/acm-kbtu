class ProblemsController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :find_contest,         :except => [:update, :update_statement]
  before_filter :find_problem,         :only => [:show, :edit, :edit_statement, :download_statement]
  before_filter :find_contest_problem, :only => [:update, :update_statement]
  load_and_authorize_resource

  rescue_from Mongoid::Errors::DocumentNotFound do |exception|
    redirect_to contest_path(params[:id]), :alert => "Problem ##{params[:problem]} not found"
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to contest_path(params[:id]), :alert => exception.message
  end

  # GET /contests/:id/problems
  def index
    #@contest = Contest.find_by(path: params[:id])    
    @navpill = 2

    @problem = @contest.problems.where(disabled: false).sort_by{|x| x.order}[1]
    if @problem.nil? 
      redirect_to contest_path(params[:id]), :alert => "There is no problems"
    else
      redirect_to contest_problem_path(params[:id], @problem.order)
    end
  end

  # GET /contests/:id/:problem
  def show
    #@contest = Contest.find_by(path: params[:id])
    #@problem = @contest.problems.find_by(order: params[:problem])
    if @problem.order == 0 || @problem.disabled == true
      redirect_to contest_path(@contest.path)
      return
    end


    @participant = current_user.participant(@contest)
    if current_user == @contest.user || current_user.admin?
      #nothing
    elsif not current_user.participate?(@contest) then
      redirect_to contest_path(@contest.path), alert: 'Please, register to participate'
      return
    elsif @contest.confirm_participants==true && @participant.confirmed==false
      redirect_to contest_path(@contest.path), alert: "Please, wait confirmation"
      return
    elsif not @contest.started?
      redirect_to contest_path(@contest.path), alert: 'Contest is not started'
      return
    end


    @submit = Submit.new({:problem => @problem, :hide => true})
    @submit.participant = @participant
    @submissions = @participant.submits.where(problem: @problem)

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
    status = @problem.put_problem(params)

    respond_to do |format|
      format.html { 
          redirect_to contest_control_problems_path(@contest.path, tab:@problem.order) 
      }
      flash[:alert]  = status[:alert]
      flash[:notice] = status[:notice]      
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

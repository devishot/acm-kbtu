class ProblemsController < ApplicationController
  # GET /contests/:id/problems
  def index
    @navpill = 1

    redirect_to "/contests/#{params[:id]}/1"
  end

  # GET /contests/:id/:problem
  def show
    @contest = Contest.find_by(path: params[:id])
    if current_user.participants.where(contest: @contest).count == 0 then
      redirect_to contest_path(@contest.path), notice: 'Please, register to participate.'
      return
    else
      participant = current_user.participants.find_by(contest: @contest)
    end
    problem = @contest.problems.find_by(order: params[:problem])

    @submit = Submit.new()
    @submit.problem = problem
    @submit.participant = participant

    @submissions = participant.submits.where(problem: problem)

    @navpill = 1
    respond_to do |format|
      format.html # show.html.erb
      #format.json { render json: @problem }
    end
  end

  # GET /contests/:id/:problem/edit
  def edit
    @contest = Contest.find_by(path: params[:id])
    @problem = @contest.problems.find_by(order: params[:problem])
  end

  # PUT '/contests/:id/:problem
  def update
    contest = Contest.find_by(path: params[:contest_path])
    @problem = contest.problems.find_by(order: params[:problem_order])

    inputs = []
    outputs = []
    3.times do |i|
      inputs << params["input"+(i+1).to_s]
      outputs << params["output"+(i+1).to_s]
    end
    @problem.statement = {:text => params[:text], :inputs => inputs, :outputs => outputs}
    @problem.unzip(params[:archive]) #and set tests_path

    respond_to do |format|
      if @problem.save
        format.html { 
          redirect_to contest_path(contest.path)+"/#{@problem.order}", 
          notice: 'Problem was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
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

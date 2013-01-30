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

  # GET /contests/:id/:problem/edit_statement
  def edit_statement
    @contest = Contest.find_by(path: params[:id])
    @problem = @contest.problems.find_by(order: params[:problem])
  end

  # PUT /contests/:id/:problem
  def update
    @contest = Contest.find(params[:contest_id])
    @problem = @contest.problems.find_by(order: params[:problem][:order])
    respond_to do |format|
      if @problem.update_attributes(params[:problem])
        format.html { redirect_to contest_path(@problem.contest.path)+"/#{@problem.order}/edit", 
          notice: 'Problem was successfully updated.' }
      else
        format.html { redirect_to contest_path(@problem.contest.path)+"/#{@problem.order}/edit",
          notice: 'ERROR: Problem was not updated.' }
      end
    end
  end    

  # PUT /contests/:id/:problem/update_statement
  def update_statement
    contest = Contest.find_by(path: params[:contest_path])
    @problem = contest.problems.find_by(order: params[:problem_order])

    inputs = []
    outputs = []
    3.times do |i|
      inputs << params["input#{i}"]
      outputs << params["output#{i}"]
    end
    @problem.statement = {:title => params[:title], 
                          :text => params[:text], 
                          :inputs => inputs, 
                          :outputs => outputs}
    #and set tests_path if uploaded
    @problem.unzip(params[:archive]) if !params[:archive].nil?
    
    respond_to do |format|
      if @problem.save
        format.html { redirect_to contest_path(contest.path)+"/#{@problem.order}", 
          notice: 'Problem\'s statement was successfully updated.' }
      else
        format.html { redirect_to contest_path(contest.path)+"/#{@problem.order}", 
          notice: 'ERROR: Problem\'s statement was not updated.' }
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

class SubmitsController < ApplicationController
  before_filter :load_contest, :except => :create
  before_filter :load_participant, :except => :create
  before_filter :load_submit, :only => [:show_sourcecode, :download_sourcecode]

  load_and_authorize_resource

  # rescue_from Mongoid::Errors::DocumentNotFound do |exception|
  #   raise exception.inspect
  #   redirect_to contests_url, :alert => "Contest ##{params[:id]} not found"
  # end


  # POST /submits
  # POST /submits.json
  def create
    @submit = Submit.create({ 
      :problem => params[:problem],
      :participant => params[:participant]
    })

    contest = @submit.problem.contest
    #return if contest OVER
    redirect_to problem_path, error: 'Contest is over' if contest.over?

    if contest.problems_count > 26 
      name_prefix = "#{@submit.problem.order}" + '#'
    else
      name_prefix = "#{(@submit.problem.order + 96).chr}"
    end
    name_prefix << "#{@submit.order}"
    name = name_prefix + File.extname( params[:file].original_filename )

    dir = @submit.folder
    path = File.join(dir, name)
    tmpfile = params[:file].tempfile

    #save sourcecode
    FileUtils.mkdir_p dir
    File.open(path, "wb") { |f| f.write(tmpfile.read) }
    @submit.sourcecode = path
    @submit.problem.submits << @submit
    @submit.participant.submits << @submit
    @submit.save!

    #raise @submit.inspect    
    #send for run
    Resque.enqueue(Tester, @submit.id)

    respond_to do |format|
      problem_path = contest_path(contest.path)+"/#{@submit.problem.order}"
      format.html { redirect_to problem_path, notice: 'Successfully submited.' }      
    end
  end


  # GET /submits/:contest/:participant
  def index
    #@contest = Contest.find_by(path: params[:contest])
    #@participant = @contest.participants.find_by(path: params[:participant])
    @submits = @participant.submits

    @navpill

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /submits/:contest/:participant/:submit
  def show_sourcecode
    #@contest = Contest.find_by(path: params[:contest])
    #@submit = Submit.find(params[:submit])

    @navpill

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @submits }
    end
  end

  # GET /submits/:contest/:participant/:submit/download
  def download_sourcecode
    #@contest = Contest.find_by(path: params[:contest])
    #@submit = Submit.find(params[:submit])

    link = @submit.file_sourcecode_path
    send_file(link)
  end

private
  def load_contest
    @contest = Contest.where(path: params[:contest]).first
    redirect_to contests_path, :alert => "Contest not found" unless @contest
  end

  def load_participant
    @participant = @contest.participants.where(path: params[:participant]).first
    redirect_to contests_path, :alert => "Participant not found" unless @participant
  end

  def load_submit
    @submit = @participant.submits.where(id: params[:submit]).first
    redirect_to contest_problem_path(@contest.path, 1), :alert => "Submit not found" unless @submit
  end

  # # GET /submits/1
  # # GET /submits/1.json
  # def show
  #   @submit = Submit.find(params[:id])

  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.json { render json: @submit }
  #   end
  # end

  # # GET /submits/new
  # # GET /submits/new.json
  # def new
  #   @submit = Submit.new

  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.json { render json: @submit }
  #   end
  # end

  # # GET /submits/1/edit
  # def edit
  #   @submit = Submit.find(params[:id])
  # end


  # PUT /submits/1
  # PUT /submits/1.json
  # def update
  #   @submit = Submit.find(params[:id])

  #   respond_to do |format|
  #     if @submit.update_attributes(params[:submit])
  #       format.html { redirect_to @submit, notice: 'Submit was successfully updated.' }
  #       format.json { head :no_content }
  #     else
  #       format.html { render action: "edit" }
  #       format.json { render json: @submit.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # DELETE /submits/1
  # # DELETE /submits/1.json
  # def destroy
  #   @submit = Submit.find(params[:id])
  #   @submit.destroy

  #   respond_to do |format|
  #     format.html { redirect_to submits_url }
  #     format.json { head :no_content }
  #   end
  # end
end

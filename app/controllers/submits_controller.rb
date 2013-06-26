class SubmitsController < ApplicationController
  before_filter :load_contest, :except => :create
  before_filter :load_participant, :except => :create
  before_filter :load_submit, :only => [:show_sourcecode, :download_sourcecode]

  load_and_authorize_resource

  # rescue_from Mongoid::Errors::DocumentNotFound do |exception|
  #   raise exception.inspect
  #   redirect_to contests_url, :alert => "Contest ##{params[:id]} not found"
  # end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to contest_path(@contest.path), :alert => exception.message
  end


  # POST /submits
  # POST /submits.json
  def create
    contest = Participant.find(params[:participant]).contest
    if contest.frozen? && contest.standings_dump.nil?
      contest.make_standings_dump!
    end

    @submit = Submit.create({ 
      :problem => params[:problem],
      :participant => params[:participant]
    })

    contest = @submit.problem.contest
    problem_path = contest_problem_path(contest.path, @submit.problem.order)
    #return if contest OVER
    if contest.over?
      redirect_to problem_path, error: 'Contest is over' 
      return
    end
    #IOI if Attempts exhausted
    if contest.ioi? && @submit.participant.attempts(@submit.problem.id)<=0
      redirect_to problem_path, error: 'Attempts exhausted'
      return
    end

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

    #send for run    
    Resque.enqueue(Tester, @submit.id) #Tester(@submit.id, hidden=false)

    respond_to do |format|
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

    link = @submit.sourcecode
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

    authorize! :read, @submit

    redirect_to contest_problem_path(@contest.path, 1), :alert => "Submit not found" unless @submit
  end

end

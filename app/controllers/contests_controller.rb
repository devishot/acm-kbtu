class ContestsController < ApplicationController
  before_filter :load_contest, :except => [:index, :kill_participant, :new, :create]
  load_and_authorize_resource  :except => [:index]

  rescue_from Mongoid::Errors::DocumentNotFound do |exception|
    redirect_to contests_url, :alert => "Contest ##{params[:id]} not found"
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to contests_url, :alert => exception.message
  end

# messages
  def messages
    #@contest = Contest.find_by(path: params[:id])
    @navpill = 4
    @messages = Message.all
  end

  def new_message
    @contest = Contest.find_by(path: params[:id])
    @message = Message.new
    @navpill = 4
  end

  def create_message
    @message = Message.new(params[:message])
    @message.participant = Participant.find_by(:user => current_user)
    @contest = Contest.find(@message.participant.contest)
    @message.save

    redirect_to contest_messages_path(@contest.path)
  end
# end messages



  # GET /contests
  # GET /contests.json
  def index
    @contests = Contest.all.sort { |a, b|
      if a.time_start.nil?
        -1
      elsif b.time_start.nil?
        1
      else       
        b.time_start <=> a.time_start
      end
    }
  end

  # GET /contests/1
  # GET /contests/1.json
  def show
    #@contest = Contest.find_by(path: params[:id])
    @navpill
  end

  def summary
    #@contest = Contest.find_by(path: params[:id])
    @navpill = 5

    if not current_user.participate? @contest
      alert = (@contest.over?) ? "Contest is over" : "Please, register to participate"
      redirect_to contest_path(@contest.path), alert: alert
      return
    end

    participant = current_user.participant(@contest)

    if @contest.confirm_participants==true && participant.confirmed==false
      redirect_to contest_path(@contest.path), alert: "Please, wait confirmation"
      return
    end

    @summary = [[]]
    @contest.problems_count.times do |i|
      problem = @contest.problems.find_by(order: i+1)
      @summary[i+1] = participant.submits.where(problem: problem)
    end
  end

  def standings
    #@contest = Contest.find_by(path: params[:id])
    @last_success = Submit.where(id: @contest.last_success_submit).first

    participants = (@contest.confirm_participants==false) ? @contest.participants : @contest.participants.where(confirmed: true)

    @standings = participants.sort do |a, b|
      if a.point == b.point then
        a.penalty <=> b.penalty
      else
        b.point <=> a.point
      end
    end

    @navpill = 3
  end

  # post /contests/:id/participate
  def participate 
    #@contest = Contest.find_by(path: params[:id])
    return if current_user==@contest.user
    return if not current_user.participants.where(contest: @contest).count == 0

    participant = Participant.new();
    @contest.participants << participant      # participant.contest will be automatically created
    current_user.participants << participant  # participant.user will be automatically created    
    participant.save

    redirect_to contest_path(@contest.path)
  end

  # delete kill_participant
  def kill_participant
    contest = Contest.find(params[:contest])
    participant = contest.participants.find(params[:participant])
    participant.destroy
    redirect_to contest_path(contest.path)+"/control"
  end  

  # POST /contests/:id/confirm_participant/:participant
  def confirm_participant
    #@contest = Contest.find_by(path: params[:id])
    participant = @contest.participants.find_by(path: params[:participant].to_i)
    participant.confirmed = (params[:value]=="false") ? false : true
    participant.save

    redirect_to contest_path(@contest.path)+"/control_participants"
  end

  # GET /contests/:id/control
  def control
    #@contest = Contest.find_by(path: params[:id])
  end

  # PUT /contests/:id/control
  def control_update
    #@contest = Contest.find_by(path: params[:id])
    if params[:commit] == "Update"
      @contest.start( params[:contest] )
      ok = 'Start time successfully updated'
      err = 'Error: Start time was not updated'

    elsif params[:commit] == "Start"
      @contest.start( params[:contest], true )
      ok = 'Contest started'
      err = 'Error: Contest was not started'

    elsif params[:commit] == "Restart"
      @contest.restart( params[:contest] )
      ok = 'Contest ReStarted'      

    elsif params[:commit] == "Stop"
      @contest.stop()
      ok = 'Contest stopped'

    elsif params[:commit] == "Continue"
      @contest.continue( params[:contest] )
      ok = 'Contest continued'
      err = 'Error: Contest was not started'
    end

    respond_to do |format|
      if @contest.save
        format.html { redirect_to contest_path(@contest.path)+'/control', notice: ok}
      else
        format.html { redirect_to contest_path(@contest.path)+'/control', alert: err}
      end
    end
  end

  # GET /contests/:id/control_problems
  def control_problems
    #@contest = Contest.find_by(path: params[:id])
  end

  # PUT /contests/:id/control_problems
  def control_problems_count
    #@contest = Contest.find_by(path: params[:id])
    @contest.upd_problems_count(params[:problems_count].to_i)

    redirect_to contest_path(@contest.path)+'/control_problems', notice: 'Problems count updated'
  end

  def control_status
    #@contest = Contest.find_by(path: params[:id])
    @submits = Submit.where(problem_contest:  @contest_id).sort_by{ |submit| submit.updated_at}.reverse
  end

  # GET /contests/:id/statement
  def download_statement
    #@contest = Contest.find_by(path: params[:id])
    if current_user == @contest.user || current_user.admin?
      #nothing
    elsif not current_user.participate?(@contest)  then
      redirect_to contest_path(@contest.path), alert: 'Please, register to participate'
      return
    elsif not @contest.started?
      redirect_to contest_path(@contest.path), alert: 'Contest is not started'
      return
    end

    participant = current_user.participant(@contest)

    if @contest.confirm_participants==true && participant.confirmed==false
      redirect_to contest_path(@contest.path), alert: "Please, wait confirmation"
      return
    end


    statement = @contest.problems.find_by(order: 0).statement['file_link']
    if statement.blank?
      redirect_to contest_path(@contest.path), alert: 'not uploaded yet'
    else    
      send_file(statement, :filename => @contest.title+File.extname(statement))
    end
  end

  # GET /contests/new
  def new
    @contest = Contest.new
  end

  # GET /contests/:id/edit
  def edit
    #@contest = Contest.find_by(path: params[:id])
  end

  # POST /contests
  def create
    @contest = Contest.new(params[:contest])
    @contest.user = current_user #author 

    respond_to do |format|
      if @contest.save
        format.html { redirect_to contest_path(@contest.path)+'/control', 
          notice: 'Contest was successfully created.' 
        }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /contests/1
  def update
    #@contest = Contest.find_by(path: params[:id])
    respond_to do |format|
      if @contest.update_attributes(params[:contest])
        format.html { redirect_to contest_path(@contest.path)+'/control' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /contests/1
  def destroy
    #@contest = Contest.find_by(path: params[:id])
    @contest.destroy

    redirect_to contests_url  
  end


private
  def load_contest
    @contest = Contest.find_by(path: params[:id])
  end

end

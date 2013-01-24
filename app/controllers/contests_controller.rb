class ContestsController < ApplicationController
  require 'zip/zipfilesystem'
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
    @contest = Contest.find_by(path: params[:id])
    @navpill
  end

  def summary
    @contest = Contest.find_by(path: params[:id])
    @navpill = 4
  end

  def messages
    @contest = Contest.find_by(path: params[:id])
    @navpill = 3
  end

  def standings
    @contest = Contest.find_by(path: params[:id])
    @navpill = 2
  end

  # post /contests/:id/participate
  def participate
    @contest = Contest.find_by(path: params[:id])
    return if current_user.participants.where(contest: @contest).count != 0

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


  # GET /contests/:id/control
  def control
    @contest = Contest.find_by(path: params[:id])
    #raise "#{@contest.participants.first.user.participants}"
  end

  # POST /contests/:id/control/update
  def control_update
    @contest = Contest.find_by(path: params[:id])

    if params[:commit] == "Update"
      @contest.time_start = Contest.new(params[:contest]).time_start
      @contest.duration = Contest.new(params[:contest]).duration
      ok = 'Start time successfully updated'
      err = 'Error: Start time was not updated'
    elsif params[:commit] == "Start"
      @contest.time_start = DateTime.now
      @contest.duration = Contest.new(params[:contest]).duration
      ok = 'Contest started'
      err = 'Error: Contest was not started'
    end

    respond_to do |format|
      if @contest.save
        format.html { redirect_to contest_path(@contest.path)+'/control', notice: ok}
      else
        format.html { redirect_to contest_path(@contest.path)+'/control', notice: err}
      end
    end
  end

  # GET /contests/new
  def new
    @contest = Contest.new
  end

  # GET /contests/:id/edit
  def edit
    @contest = Contest.find_by(path: params[:id])
  end

  # POST /contests
  def create
    @contest = Contest.new(params[:contest])
    
    respond_to do |format|
      if @contest.save
        if @contest.problems_upload == 0 #one_archive
          format.html { redirect_to contest_path(@contest.path)+'/upload', 
            notice: 'Contest was successfully created.' 
          }
        else
          @contest.problems_create()
          format.html { redirect_to contest_path(@contest.path),
            notice: 'Contest was successfully created.' 
          }          
        end
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /contests/1
  def update
    @contest = Contest.find_by(path: params[:id])

    respond_to do |format|
      if @contest.update_attributes(params[:contest])
        format.html { redirect_to contest_path(@contest.path)+'/upload' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /contests/1
  def destroy
    @contest = Contest.find_by(path: params[:id])
    @contest.destroy

    redirect_to contests_url  
end

  # GET /contests/:id/upload
  def upload
    @contest = Contest.find_by(path: params[:id])
  end

  # POST /contests/:id/unpack
  def unpack
    contest = Contest.find_by(path: params[:id])

    contest.unpack(params[:archive])
    contest.problems.destroy_all #destroy perviouse problems!!!
    contest.problems_create()

    respond_to do |format|
      format.html { redirect_to contest_path(contest.path) }
    end    
  end
end

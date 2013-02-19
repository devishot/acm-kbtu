class ContestsController < ApplicationController
  before_filter :load_contest,
                :except => [:index, :kill_participant, :new, :create]
  #load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

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
    @navpill = 4
  end

# messages
  def messages
    #@contest = Contest.find_by(path: params[:id])
    @navpill = 3
    @messages = Message.all
  end

  def new_message
    @contest = Contest.find_by(path: params[:id])
    @message = Message.new
    @navpill = 3
  end

  def create_message
    @message = Message.new(params[:message])
    @message.participant = Participant.find_by(:user => current_user)
    @contest = Contest.find(@message.participant.contest)

    @message.save

    redirect_to contest_messages_path(@contest.path)
  end
# end messages

  def standings
    #@contest = Contest.find_by(path: params[:id])

    @last_success = Submit.where(status: "AC").last
    @last_success = nil if @last_success.to_a == nil

    @navpill = 2
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

  # # GET /contests/:id/statement
  # def download_statement
  #   #@contest = Contest.find_by(path: params[:id])
  #   if @contest.statement_link.nil?
  #     redirect_to contest_path(@contest.path), 
  #                 alert: 'not uploaded yet'
  #   else    
  #     send_file(@contest.statement_link,
  #               :filename => "statement.pdf",
  #               :type => "application/pdf")
  #   end
  # end

  # GET /contests/:id/control
  def control
    #@contest = Contest.find_by(path: params[:id])
  end

  # # POST /contests/:id/control/update
  # def control_update
  #   #@contest = Contest.find_by(path: params[:id])
  #   if params[:commit] == "Update"
  #     @contest.time_start = Contest.new(params[:contest]).time_start
  #     @contest.duration = Contest.new(params[:contest]).duration
  #       ok = 'Start time successfully updated'
  #       err = 'Error: Start time was not updated'
  #   elsif params[:commit] == "Start"
  #     @contest.time_start = DateTime.now
  #     @contest.duration = Contest.new(params[:contest]).duration
  #       ok = 'Contest started'
  #       err = 'Error: Contest was not started'
  #   end

  #   respond_to do |format|
  #     if @contest.save
  #       format.html { redirect_to contest_path(@contest.path)+'/control', notice: ok}
  #     else
  #       format.html { redirect_to contest_path(@contest.path)+'/control', alert: err}
  #     end
  #   end
  # end

  # GET /contests/:id/control_problems
  def control_problems
    #@contest = Contest.find_by(path: params[:id])
    #raise "#{session.inspect}"
    @contest.problems.each do |problem| 
      id = session["solution_#{problem.order}_id"]
      next if id.nil?
      next if not session["solution_#{problem.order}_status"].nil?
      submit = Submit.find(id)
      session["solution_#{problem.order}_status"] = submit.status
      session["solution_#{problem.order}_status_full"] = submit.status_full
    end
    #raise "#{session.inspect}"

  end

  # PUT /contests/:id/control_problems
  def control_problems_count
    #@contest = Contest.find_by(path: params[:id])
    @contest.upd_problems_count(params[:problems_count].to_i)

    redirect_to contest_path(@contest.path)+'/control_problems',
                notice: 'Problems count updated'
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

  # # PUT /contests/1/update_mode
  # def update_mode
  #   #@contest = Contest.find_by(path: params[:id])
  #   if params[:contest][:problems_upload] != @contest.problems_upload
  #     @contest.clear
  #   end

  #   respond_to do |format|
  #     if @contest.update_attributes(params[:contest])
  #       #create new problem
  #       @contest.problems_create

  #       format.html { redirect_to contest_path(@contest.path)+'/control' }
  #     else
  #       format.html { redirect_to contest_path(@contest.path)+'/control',
  #         alert: "ERROR: Was not updated"
  #       }
  #     end
  #   end
  # end


  # DELETE /contests/1
  def destroy
    #@contest = Contest.find_by(path: params[:id])
    @contest.destroy

    redirect_to contests_url  
  end

  # # GET /contests/:id/upload
  # def upload
  #   #@contest = Contest.find_by(path: params[:id])
  # end

  # # POST /contests/:id/unpack
  # def unpack
  #   #@contest = Contest.find_by(path: params[:id])

  #   @contest.unpack(params[:archive])
  #   @contest.problems.destroy_all #destroy perviouse problems!!!
  #   @contest.problems_create(params[:statement])

  #   respond_to do |format|
  #     format.html { redirect_to contest_path(@contest.path)+'/control' }
  #   end    
  # end


private
  def load_contest
    @contest = Contest.find_by(path: params[:id])
  end

end

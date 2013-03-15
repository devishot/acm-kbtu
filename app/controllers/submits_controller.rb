class SubmitsController < ApplicationController
  before_filter :load_contest_participant, :except => [:create]
  before_filter :load_submit, :only => [:show_sourcecode, :download_sourcecode]

  # POST /submits
  # POST /submits.json
  def create
    @submit = Submit.new({ 
      :problem => params[:problem],
      :participant => params[:participant]
    })
    contest = @submit.problem.contest
    #return if contest OVER
    redirect_to problem_path, error: 'Contest is over' if contest.over?

    if contest.problems_count > 26 
      name_prefix = "#{@submit.problem.order}"+'#'
    else
      name_prefix = "#{(@submit.problem.order + 96).chr}"
    end
    name_prefix << "#{@submit.participant.submits.where(problem: @submit.problem).count + 1}"
    name = name_prefix+File.extname( params[:file].original_filename )

    directory = @submit.participant.participant_dir+"/#{@submit.problem.order}"
    path = File.join(directory, name)
    tmpfile = params[:file].tempfile
    @submit.file_sourcecode_path = path
    

    respond_to do |format|
      problem_path = contest_path(contest.path)+"/#{@submit.problem.order}"
      if @submit.save
        #save sourcecode
        FileUtils.mkdir_p directory
        File.open(path, "wb") { |f| f.write(tmpfile.read) }

        (@submit.problem).submits << @submit
        (@submit.participant).submits << @submit

        Resque.enqueue(Tester, @submit.id)

        format.html { redirect_to problem_path, notice: 'Successfully submited.' }
      else
        format.html { redirect_to problem_path, alarm: 'ERROR! Check and try again.' }
      end
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
    #@participant = @contest.participants.find_by(path: params[:participant])
    #@submit = @participant.submits[params[:submit].to_i-1]
    @order = params[:submit].to_i

    @navpill

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @submits }
    end
  end

  # GET /submits/:contest/:participant/:submit/download
  def download_sourcecode
    #@contest = Contest.find_by(path: params[:contest])
    #@participant = @contest.participants.find_by(path: params[:participant])
    #@submit = @participant.submits[params[:submit].to_i-1]
    link = @submit.file_sourcecode_path
    send_file(link)
  end

private
  def load_contest_participant
    @contest = Contest.find_by(path: params[:contest])
    @participant = @contest.participants.find_by(path: params[:participant]) 
  end

  def load_submit
    @submit = @participant.submits[params[:submit].to_i-1]
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

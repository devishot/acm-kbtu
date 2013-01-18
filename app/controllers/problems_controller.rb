class ProblemsController < ApplicationController
  # GET /contests/:id/problems
  def index
    @navpill = 1

    respond_to do |format|
      format.html { redirect_to "/contests/#{params[:id]}/1" }
      #format.json { render json: @problems }
    end
  end

  # GET /contests/:id/:problem
  def show
    contest = Contest.find_by(path: params[:id])
    if current_user.participants.where(contest: contest).count == 0 then
      redirect_to contest_path(contest.path), notice: 'Please, register to participate.'
      return
    else
      participant = current_user.participants.find_by(contest: contest)
    end
    problem = contest.problems.find_by(order: params[:problem])

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
    contest = Contest.find_by(path: params[:id])
    @problem = contest.problems.find_by(order: params[:problem])
  end

  # PUT '/contests/:id/:problem
  def update
    contest = Contest.find_by(path: params[:contest_path])
    @problem = contest.problems.find_by(order: params[:problem_order])

    inputs = []
    outputs = []
    3.times do |i|
      inputs << params["inputs"+(i+1).to_s]
      outputs << params["outputs"+(i+1).to_s]
    end
    @problem.statement = {:text => params[:text], :inputs => inputs, :outputs => outputs}
    @problem.tests_path = archive_unzip(@problem)+'/tests'

    respond_to do |format|
      if @problem.save
        format.html { 
          redirect_to contest_path(contest.path)+"/#{@problem.order}", 
          notice: 'Problem was successfully updated.' }
        #format.json { head :no_content }
      else
        format.html { render action: "edit" }
        #format.json { render json: @problem.errors, status: :unprocessable_entity }
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
private
  def archive_unzip(problem) 
    uploaded_zip = params[:archive]    
    problem_dir = "#{Rails.root}/public/problems/#{problem.global_path}"

    FileUtils.mkdir_p problem_dir unless File.directory? problem_dir

    #write file(.zip) in problem_dir
    File.open(Rails.root.join(problem_dir, uploaded_zip.original_filename), 'w') do |file|
      file.write(uploaded_zip.read.force_encoding('utf-8'))
    end

    #exctract files from file(.zip)
    Zip::ZipFile.open(problem_dir+"/#{uploaded_zip.original_filename}"){ |zip_file|
      zip_file.each { |f|
        f_path=File.join(problem_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }

    #remove(delete) file(.zip)
    FileUtils.remove_file(problem_dir+"/#{uploaded_zip.original_filename}")

    return problem_dir
  end

end

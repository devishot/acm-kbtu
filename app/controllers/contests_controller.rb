class ContestsController < ApplicationController
  require 'zip/zipfilesystem'
  # GET /contests
  # GET /contests.json
  def index
    @contests = Contest.all
  end

  # GET /contests/1
  # GET /contests/1.json
  def show
    @contest = Contest.find_by(path: params[:id])
    @navpill
    #destroy participate
    #@contest.participants.delete(@contest.participants.last)
    #current_user.participants.delete(current_user.participants.last)    
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

  def participate
    @contest = Contest.find_by(path: params[:id])
    if current_user.participants.where(contest: @contest).count != 0 then
      redirect_to contest_path(@contest.path), notice: 'You are already participate.'
      return
    end

    participant = Participant.new();
    @contest.participants << participant
    current_user.participants << participant
    participant.save
    #@contest.participants.delete(@contest.participants.last)
    #current_user.participants.delete(current_user.participants.last)
    redirect_to contest_path(@contest.path)
  end

  # GET /contests/new
  # GET /contests/new.json
  def new
    @contest = Contest.new
  end

  # GET /contests/1/edit
  def edit
    @contest = Contest.find_by(path: params[:id])
  end

  # POST /contests
  # POST /contests.json
  def create
    @contest = Contest.new(params[:contest])
    
    respond_to do |format|
      if @contest.save
        format.html { redirect_to contest_path(@contest.path)+'/upload', 
          notice: 'Contest was successfully created.' 
        }
        #format.json { render json: @contest, status: :created, location: @contest }
      else
        format.html { render action: "new" }
        #format.json { render json: @contest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /contests/1
  # PUT /contests/1.json
  def update
    @contest = Contest.find_by(path: params[:id])

    respond_to do |format|
      if @contest.update_attributes(params[:contest])
        format.html { redirect_to contest_path(@contest.path)+'/upload', 
          notice: 'Contest was successfully updated.' 
        }
        #format.json { head :no_content }
      else
        format.html { render action: "edit" }
        #format.json { render json: @contest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contests/1
  # DELETE /contests/1.json
  def destroy
    @contest = Contest.find_by(path: params[:id])
    archive_delete(@contest.path)
    problems_destroy(@sontest)
    @contest.destroy

    respond_to do |format|
      format.html { redirect_to contests_url }
      #format.json { head :no_content }
    end
  end

  def archive_uploader
    @contest = Contest.find_by(path: params[:id])
  end

  def archive_unzip
    #initialize
    unless File.directory? "#{Rails.root}/public/contests"
      FileUtils.mkdir "#{Rails.root}/public/contests"
    end

    contest = Contest.find_by(path: params[:contest_id])
    contest.problems_count = params[:problems_count]
    contest.save
    uploaded_zip = params[:archive]    
    contest_dir = "#{Rails.root}/public/contests/#{contest.path}"

    unless File.directory? contest_dir
      FileUtils.mkdir contest_dir
    end

    #write file(.zip) in contest_dir
    File.open(Rails.root.join(contest_dir, uploaded_zip.original_filename), 'w') do |file|
      file.write(uploaded_zip.read.force_encoding('utf-8'))
    end

    #exctract files(folders) from file(.zip)
    Zip::ZipFile.open(contest_dir+"/#{uploaded_zip.original_filename}"){ |zip_file|
      zip_file.each { |f|
        f_path=File.join(contest_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      }
    }

    #remove(delete) file(.zip)
    FileUtils.remove_file(contest_dir+"/#{uploaded_zip.original_filename}")

    problems_create(contest, contest_dir)

    respond_to do |format|
      format.html { redirect_to contest_path(contest.path) }
      #format.json { head :no_content }
    end    
  end

private
  def archive_delete(contest_id)
    contest_dir = "#{Rails.root}/public/contests/#{contest_id}"

    if File.directory? contest_dir
      FileUtils.remove_dir contest_dir
    end
  end

  def problems_create(contest, contest_dir)
    for i in 1..contest.problems_count
      problem = Problem.new();
      problem.contest = contest
      problem.order = i
      problem.tests_path = contest_dir + '/problems/' + ('A'.ord + i - 1).chr
      problem.save
      contest.problems << problem
      contest.save
    end
  end

  def problems_destroy(contest)
    contest.problems.each do |problem|
      problem.submits.destroy_all
      problem.destroy
    end
  end
end

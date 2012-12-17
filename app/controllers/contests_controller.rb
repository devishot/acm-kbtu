class ContestsController < ApplicationController
  require 'zip/zipfilesystem'
  # GET /contests
  # GET /contests.json
  def index
    @contests = Contest.all

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @contests }
    end
  end

  # GET /contests/1
  # GET /contests/1.json
  def show
    @contest = Contest.find_by(path: params[:id])

    respond_to do |format|
      format.html # show.html.erb
      #format.json { render json: @contest }
    end
  end

  # GET /contests/new
  # GET /contests/new.json
  def new
    @contest = Contest.new

    respond_to do |format|
      format.html # new.html.erb
      #format.json { render json: @contest }
    end
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
        format.html { redirect_to contests_path+'/'+@contest.path+'/upload', notice: 'Contest was successfully created.' }
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
        format.html { redirect_to contests_path+'/'+@contest.path, notice: 'Contest was successfully updated.' }
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
    @contest.destroy

    respond_to do |format|
      format.html { redirect_to contests_url }
      #format.json { head :no_content }
    end
  end

  def problems_uploader
    @contest = Contest.find_by(path: params[:id])
  end


  def problems_unzip
    #initialize
    unless File.directory? "#{Rails.root}/public/contests"
      FileUtils.mkdir "#{Rails.root}/public/contests"
    end

    @contest = Contest.find_by(path: params[:contest_id])
    uploaded_zip = params[:archive]    
    contest_dir = "#{Rails.root}/public/contests/#{@contest.path}"

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

    respond_to do |format|
      format.html { redirect_to contests_path+'/'+@contest.path }
      #format.json { head :no_content }
    end    
  end

end

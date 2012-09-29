class PagesController < ApplicationController
  #load_and_authorize_resource

  before_filter :authenticate_user!, :except => [:main, :show]

  # GET /pages
  # GET /pages.json
  def main
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }
    #@home_pages = Node.find_by(name: "Home").pages
  end

  def list
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }
    @users = User.all
  end

  def account
    @pages = current_user.pages
  end


  def index
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
    node = Node.find_by(path: params[:node])
    @page = node.page.find_by(path: params[:page])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.json
  def new
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }
    @page = Page.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @page }
    end
  end

  # GET /pages/1/edit
  def edit
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }

    node = Node.find_by(path: params[:node])
    @page = node.page.find_by(path: params[:page])
    @page.old_path = @page.path
    @page.old_node = @page.node.path
  end

  # POST /pages
  # POST /pages.json
  def create

    @page = Page.new(params[:page])
    @page.author = current_user.name
    current_user.pages << @page
    #@page.user = current_user

    parent = Node.find_by(path: "#{params[:page][:parent]}")
    parent.page << @page

    respond_to do |format|
      format.html { redirect_to list_path, notice: 'Page was successfully created.' }
      format.json { render json: list_path, status: :created, location: list_path }
    end

    # respond_to do |format|
    #   if @page.save
    #     format.html { redirect_to @page, notice: 'Page was successfully created.' }
    #     format.json { render json: @page, status: :created, location: @page }
    #   else
    #     format.html { render action: "new" }
    #     format.json { render json: @page.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update

    if params[:page][:parent] != params[:page][:old_node] || params[:page][:path] != params[:page][:old_path]
      old_node = Node.find_by(path: params[:page][:old_node])
      old_page = old_node.page.find_by(path: params[:page][:old_path])
      old_node.page.delete(old_page)

      new_node = Node.find_by(path: "#{params[:page][:parent]}")
      new_node.page << Page.new(params[:page])

      respond_to do |format|
        format.html { redirect_to list_path, notice: 'Page was successfully updated.' }
        format.json { head :no_content }
      end
    else
      node = Node.find_by(path: params[:page][:parent])
      @page = node.page.find_by(path: params[:page][:path])

      respond_to do |format|
        if @page.update_attributes(params[:page])
          format.html { redirect_to list_path, notice: 'Page was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @page.errors, status: :unprocessable_entity }
        end
      end
    end

  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy

    node = Node.find_by(path: params[:node])
    @page = node.page.find_by(path: params[:page])

    node.page.delete(@page)

    respond_to do |format|
      format.html { redirect_to list_path }
      format.json { head :no_content }
    end
  end
end

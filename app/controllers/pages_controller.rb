class PagesController < ApplicationController
  #load_and_authorize_resource

  #before_filter :authenticate_user!, :except => [:main, :show]
  load_and_authorize_resource :except => [:main, :show]

  # GET /pages
  # GET /pages.json
  def main
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }
    @node = Node.find_by(order: 1)
    #@home_pages = Node.find_by(name: "Home").pages
  end

  def list
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }
    @users = User.all
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
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }
    node = Node.find_by(path: params[:node])
    @page = node.pages.find_by(path: params[:page])

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
    @page = node.pages.find_by(path: params[:page])
    @page.old_node = @page.node.path

    if cannot? :update, @page
      redirect_to '/nodes/'+node.path, alert: 'You have not permissions to edit this Page.'
    end
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = Page.new(params[:page])

    parent = Node.find_by(path: "#{params[:page][:parent]}")
    parent.inc(:count_pages_in_node, 1)
    parent.save
    @page.order = parent.count_pages_in_node

    respond_to do |format|
      if @page.save
        parent.pages << @page
        current_user.pages << @page
        format.html { redirect_to '/nodes/'+parent.path, notice: 'Page was successfully created.' }
        format.json { render json: '/nodes/'+parent.path, status: :created, location: list_path }
      else
        format.html { render action: "new" }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end

  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update

    if params[:page][:parent] != params[:page][:old_node]
      old_node = Node.find_by(path: params[:page][:old_node])
      old_page = old_node.pages.find_by(path: params[:page][:path])

      new_node = Node.find_by(path: "#{params[:page][:parent]}")
      new_page = Page.new(params[:page])

      respond_to do |format|
        if new_page.save
          new_node.pages << new_page
          (old_page.user).pages << new_page
          (old_page.user).pages.delete(old_page)
          old_node.pages.delete(old_page)
          old_page.destroy

          format.html { redirect_to '/nodes/'+new_node.path, notice: 'Page was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @page.errors, status: :unprocessable_entity }          
        end
      end
    else
      node = Node.find_by(path: params[:page][:parent])
      @page = node.pages.find_by(path: params[:page][:path])

      respond_to do |format|
        if @page.update_attributes(params[:page])
          format.html { redirect_to '/nodes/'+node.path, notice: 'Page was successfully updated.' }
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
    @page = node.pages.find_by(path: params[:page])

    if can? :destroy, @page
      node.pages.delete(@page)
      (@page.user).pages.delete(@page)
      @page.destroy

      respond_to do |format|
        format.html { redirect_to '/nodes/'+node.path, notice: 'Page was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      redirect_to '/nodes/'+node.path, alert: 'You have not permissions to destroy this Page.'
    end

  end
end

class PagesController < ApplicationController
  load_and_authorize_resource :except => [:main, :show]

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
  

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
      #format.json { render json: @pages }
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
      #format.json { render json: @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.json
  def new
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }

    @page = Page.new

    respond_to do |format|
      format.html # new.html.erb
      #format.json { render json: @page }
    end
  end

  # GET /pages/1/edit
  def edit
    @nodes = Node.all.sort { |a, b| a.order <=> b.order }

    node = Node.find_by(path: params[:node])
    @page = node.pages.find_by(path: params[:page])
    @page.old_node = @page.node.id

    if cannot? :update, @page
      redirect_to '/nodes/'+node.path, alert: 'You have not permissions to edit this Page.'
    end
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = Page.new(params[:page])

    respond_to do |format|
      if @page.save
        after_save_page(@page)

        format.html { redirect_to '/nodes/'+(@page.node).path, notice: 'Page was successfully created.' }
        #format.json { render json: '/nodes/'+(@page.node).path, status: :created, location: list_path }
      else
        format.html { render action: "new" }
        #format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end

  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update
    @new_page = Page.new(params[:page])
    @old_page = ( Node.find_by(id: params[:page][:old_node]) ).pages.find_by(path: params[:page][:path])

    respond_to do |format|
      if @new_page.save
        delete_page(@old_page)
        after_save_page(@new_page)

        format.html { redirect_to '/nodes/'+@new_page.node.path, notice: 'Page was successfully updated.' }
        #format.json { head :no_content }        
      else
        format.html { render "/pages/#{@new_page.node.path}/#{@new_page.path}/edit" }
        #format.json { render json: @page.errors, status: :unprocessable_entity }                  
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy
    node = Node.find_by(path: params[:node])
    @page = node.pages.find_by(path: params[:page])

    if can? :destroy, @page
      delete_page(@page)

      respond_to do |format|
        format.html { redirect_to '/nodes/'+node.path, notice: 'Page was successfully destroyed.' }
        #format.json { head :no_content }
      end
    else
      redirect_to '/nodes/'+node.path, alert: 'You have not permissions to destroy this Page.'
    end
  end

private 
  def delete_page(page)
    (page.node).inc(:count_pages_in_node, -1)
    (page.node).save
    (page.node).pages.delete(page)    
    (page.user).pages.delete(page)
    page.destroy
  end

  def after_save_page(page)
    (page.node).inc(:count_pages_in_node, 1)
    (page.node).save
    page.order = (page.node).count_pages_in_node
    page.save
    (page.node).pages << @page
    current_user.pages << @page
  end
end

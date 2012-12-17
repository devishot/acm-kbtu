class NodesController < ApplicationController
  #load_and_authorize_resource

  #before_filter :authenticate_user!, :except => [:show]
  load_and_authorize_resource :except => [:show, :upd_order]
  skip_before_filter :verify_authenticity_token, :only => [:upd_pages_order, :upd_nodes_order]

  # GET /nodes
  # GET /nodes.json
  def index
    @nodes = Node.all.sort{ |a, b| a.order <=> b.order }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @nodes }
    end
  end

  # POST
  def upd_pages_order
    json = JSON.parse( params[:json].to_json )
    node = Node.find_by(path: json['node'])
    pages = node.pages
    t = node.pages.count
    str = json["order"]
    str.each do |path|
      page = pages.find_by(path: path)
      page.order = t
      page.save
      t = t - 1
    end

    respond_to do |format|
       format.html { redirect_to list_path, notice: '###' }
       format.json { render json: list_path, status: :created, location: list_path }
    end
  end


  # POST
  def upd_nodes_order
    order_list = params[:order]
    nodes = Node.all
    t = 1
    order_list.each do |node_path|
      node = nodes.find_by(path: node_path)
      node.order = t
      node.save
      t += 1
    end

    respond_to do |format|
       format.html { redirect_to list_path, notice: '###' }
       format.json { render json: list_path, status: :created, location: list_path }
    end    
  end

  # GET /nodes/1
  # GET /nodes/1.json
  def show
    @nodes = Node.all.sort{ |a, b| a.order <=> b.order }
    @node = Node.find_by(path: params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @node }
    end
  end

  # GET /nodes/new
  # GET /nodes/new.json
  def new
    @node = Node.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @node }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = Node.find(params[:id])
  end

  # POST /nodes
  # POST /nodes.json
  def create
    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        format.html { redirect_to list_path, notice: 'Node was successfully created.' }
        format.json { render json: list_path, status: :created, location: list_path }
      else
        format.html { render action: "new" }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /nodes/1
  # PUT /nodes/1.json
  def update
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.html { redirect_to list_path, notice: 'Node was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.json
  def destroy
    @node = Node.find(params[:id])

    @node.pages.each do |page|
      (page.user).pages.delete(page)
    end

    @node.pages.delete_all
    @node.destroy

    respond_to do |format|
      format.html { redirect_to list_path }
      format.json { head :no_content }
    end
  end
end

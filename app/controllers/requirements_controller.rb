class RequirementsController < ApplicationController

  before_filter :require_admin
  before_filter :set_current_requirement, :only => [:show, :edit, :update, :destroy]

  # ------------- before filter methods ------------- #
  def set_current_requirement
    @requirement = Requirement.find(params[:id])
  end
  # ------------- end before filter methods ------------- #

  # GET /requirements
  def index
    @requirements = Requirement.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /requirements/1
  def show
    # @reqSteps = RequirementStep.order("position")

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /requirements/new
  def new
    @requirement = Requirement.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /requirements/1/edit
  def edit
  end

  # POST /requirements
  def create
    @requirement = Requirement.new(params[:requirement])
     respond_to do |format|
      if @requirement.save
        format.html { redirect_to(@requirement, :notice => 'Requirement was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /requirements/1
  def update
    respond_to do |format|
      if @requirement.update_attributes(params[:requirement])
        format.html { redirect_to(@requirement, :notice => 'Requirement was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /requirements/1
  def destroy
    @requirement.destroy(:force)

    respond_to do |format|
      format.html { redirect_to(requirements_url) }
    end
  end
end

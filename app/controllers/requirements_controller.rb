class RequirementsController < ApplicationController

  before_filter :require_admin
  before_filter :set_current_requirement, :only => [:show, :edit, :update, :destroy]

  # ------------- before filter methods ------------- #
  def set_current_requirement
    @requirement = Requirement.find(params[:id])
  end
  # ------------- end before filter methods ------------- #

  def index
    @requirements = Requirement.all
  end

  def show
  end

  def new
    @requirement = Requirement.new
  end

  def edit
  end

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

  def update
    respond_to do |format|
      if @requirement.update_attributes(params[:requirement])
        format.html { redirect_to(@requirement, :notice => 'Requirement was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @requirement.destroy(:force)

    respond_to do |format|
      format.html { redirect_to(requirements_url) }
    end
  end
end

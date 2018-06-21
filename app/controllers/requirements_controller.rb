# frozen_string_literal: true

class RequirementsController < ApplicationController
  load_and_authorize_resource
  before_action :set_current_requirement,
                only: %i[show edit update destroy]

  # ------------- before filter methods ------------- #
  def set_current_requirement
    @requirement = Requirement.find(params[:id])
  end
  # ------------- end before filter methods ------------- #

  def index
    @requirements = Requirement.all
  end

  def show; end

  def new
    @requirement = Requirement.new
  end

  def edit; end

  def create
    @requirement = Requirement.new(requirement_params)
    if @requirement.save
      redirect_to @requirement, notice: 'Requirement was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    if @requirement.update_attributes(requirement_params)
      redirect_to @requirement, notice: 'Requirement was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @requirement.destroy
    redirect_to requirements_url
  end

  private

  def requirement_params
    params.require(:requirement)
          .permit(:user_id, :user_ids, :equipment_model_id, :contact_info,
                  :description, { equipment_model_ids: [] }, :notes,
                  :contact_name)
  end
end

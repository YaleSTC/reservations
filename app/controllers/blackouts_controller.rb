class BlackoutsController < ApplicationController

  load_and_authorize_resource
  before_filter :set_params_for_create_and_update, only: [:create, :create_recurring, :update]
  before_filter :set_current_blackout, only: [:edit, :show, :update, :destroy, :destroy_recurring]
  before_filter :validate_recurring_date_params, only: [:create_recurring]


  # ---------- before filter methods ------------ #

  def set_params_for_create_and_update
    params[:blackout][:created_by] = current_user[:id] # Last-edited-by is automatically set
    params[:blackout][:equipment_model_id] = 0 # If per-equipment_model blackouts are implemented, delete this line.
  end

  def set_current_blackout
    @blackout = Blackout.find(params[:id])
  end

  #validates that date selection was done correctly when the form calls the create method
  def validate_recurring_date_params
    set_flash_errors
    if flash[:error]
      # exit
      respond_to do |format|
        format.html {redirect_to :back and return}
        format.js {render action: 'load_custom_errors' and return}
      end
    end
  end

  # ---------- end before filter methods ------------ #

  def index
    @blackouts = Blackout.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def show
    unless @blackout.set_id.nil?
      @blackout_set = Blackout.where("set_id = ?", @blackout.set_id)
    end
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def new
    @blackout = Blackout.new
    set_dates_for_datepicker

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def new_recurring
    @blackout = Blackout.new
    set_dates_for_datepicker

    respond_to do |format|
      format.html{render "new_recurring"}
    end
  end

  def edit
  end

  #called when a recurring blackout is needed
  def create_recurring
    # this class method will parse the params hash and create separate blackouts on each appropriate date
    # method will return an error message if save is not successful
    flash[:error] = Blackout.create_blackout_set(params[:blackout])

    respond_to do |format|
      # if there is an error, show it and redirect :back
      if flash[:error]
        format.html {redirect_to :back and return}
        format.js {render action: 'load_custom_errors' and return}
      else
        format.html { redirect_to blackouts_path, notice: 'Blackouts were successfully created.' }
        format.js { render action: "create_success" }
      end
    end

  end

  def create
    # create a non-recurring blackout
    @blackout = Blackout.new(params[:blackout])

    # save and exit
    respond_to do |format|
      if @blackout.save
        format.html { redirect_to @blackout, notice: 'Blackout was successfully created.' }
        format.js {render action: 'create_success' and return}
      else
        format.html { render action: "new" }
        format.js { render action: 'load_custom_errors', notice: 'Unable to save blackout date.' and return}
      end
    end
  end

  def update
    unless @blackout.set_id.nil?
      @blackout_set = Blackout.where("set_id = ?", @blackout.set_id)
      if @blackout_set.size <= 2
        @blackout_set.each do |b|
          b.set_id = NIL
          b.save
        end
      else # individual edited reservations no longer belong to the set (so won't be mass-deleted in delete_recurring)
        @blackout.set_id = NIL
      end
    end

    respond_to do |format|
      if @blackout.update_attributes(params[:blackout])
        format.html { redirect_to @blackout, notice: 'Blackout was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy
    @blackout.destroy(:force)

    respond_to do |format|
      format.html { redirect_to blackouts_url }
    end
  end

  def destroy_recurring
    blackout_set = Blackout.where("set_id = ?", @blackout.set_id)
    blackout_set.each do |blackout|
      blackout.destroy(:force)
    end

    # exit
    flash[:notice] = "All blackouts in the set were successfully destroyed."
    redirect_to blackouts_path and return
  end

  private
    def set_flash_errors
      # make sure there are actually days selected
      if params[:blackout][:days].first.blank?
        flash[:error] = 'You must select at least one day of the week for any recurring blackouts to be created.'
        return
      end

      if params[:blackout][:blackout_type] != 'hard' && params[:blackout][:blackout_type] != 'soft'
        flash[:error] = 'Please select a blackout type.'
        return
      end

      if params[:blackout][:notice] == ''
        flash[:error] = 'Please provide a short description of the blackout.'
        return
      end
    end

    def set_dates_for_datepicker
      @blackout[:start_date] = Date.today # Necessary for datepicker functionality
      @blackout[:end_date] = Date.today # Necessary for datepicker functionality
    end
end

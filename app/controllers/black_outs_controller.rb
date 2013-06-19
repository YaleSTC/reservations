class BlackOutsController < ApplicationController

  before_filter :require_admin
  before_filter :set_params_for_create_and_update, :only => [:create, :create_recurring, :update]
  before_filter :set_current_blackout, :only => [:edit, :show, :update, :destroy, :destroy_recurring]
  before_filter :validate_recurring_date_params, :only => [:create_recurring]


  # ---------- before filter methods ------------ #

  def set_params_for_create_and_update
    # correct for date formatting
    params[:black_out][:start_date] = Date.strptime(params[:black_out][:start_date],'%m/%d/%Y')
    params[:black_out][:end_date] = Date.strptime(params[:black_out][:end_date],'%m/%d/%Y')

    # make sure dates are valid
    if params[:black_out][:end_date] < params[:black_out][:start_date]
      flash[:error] = 'Due date must be after the start date.'
      redirect_to :back and return
    end

    params[:black_out][:created_by] = current_user[:id] # Last-edited-by is automatically set
    params[:black_out][:equipment_model_id] = 0 # If per-equipment_model blackouts are implemented, delete this line.
  end

  def set_current_blackout
    @black_out = BlackOut.find(params[:id])
  end

  #validates that date selection was done correctly when the form calls the create method
  def validate_recurring_date_params
    set_flash_errors
    if flash[:error]
      # exit
      respond_to do |format|
        format.html {redirect_to :back and return}
        format.js {render :action => 'load_custom_errors' and return}
      end
    end
  end

  # ---------- end before filter methods ------------ #

  def index
    @black_outs = BlackOut.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def show
    unless @black_out.set_id.nil?
      @black_out_set = BlackOut.where("set_id = ?", @black_out.set_id)
    end
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def new
    @black_out = BlackOut.new
    @black_out[:start_date] = Date.today # Necessary for datepicker functionality
    @black_out[:end_date] = Date.today # Necessary for datepicker functionality

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def new_recurring
    @black_out = BlackOut.new
    @black_out[:start_date] = Date.today # Necessary for datepicker functionality
    @black_out[:end_date] = Date.today # Necessary for datepicker functionality

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
    flash[:error] = BlackOut.create_black_out_set(params[:black_out])

    respond_to do |format|
      # if there is an error, show it and redirect :back
      if flash[:error]
        format.html {redirect_to :back and return}
        format.js {render :action => 'load_custom_errors' and return}
      else
        format.html { redirect_to black_outs_path, notice: 'Blackouts were successfully created.' }
        format.js { render :action => "create_success" }
      end
    end

  end

  def create
    # create a non-recurring blackout
    @black_out = BlackOut.new(params[:black_out])

    # save and exit
    respond_to do |format|
      if @black_out.save
        format.html { redirect_to @black_out, notice: 'Blackout was successfully created.' }
        format.js {render :action => 'create_success' and return}
      else
        format.html { render action: "new" }
        format.js { render :action => 'load_custom_errors', notice: 'Unable to save blackout date.' and return}
      end
    end
  end

  def update
    unless @black_out.set_id.nil?
      @black_out_set = BlackOut.where("set_id = ?", @black_out.set_id)
      if @black_out_set.size <= 2
        @black_out_set.each do |b|
          b.set_id = NIL
          b.save
        end
      else # individual edited reservations no longer belong to the set (so won't be mass-deleted in delete_recurring)
        @black_out.set_id = NIL
      end
    end

    respond_to do |format|
      if @black_out.update_attributes(params[:black_out])
        format.html { redirect_to @black_out, notice: 'Blackout was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy
    @black_out.destroy(:force)

    respond_to do |format|
      format.html { redirect_to black_outs_url }
    end
  end

  def destroy_recurring
    black_out_set = BlackOut.where("set_id = ?", @black_out.set_id)
    black_out_set.each do |black_out|
      black_out.destroy(:force)
    end

    # exit
    flash[:notice] = "All blackouts in the set were successfully destroyed."
    redirect_to black_outs_path and return
  end

  private
    def set_flash_errors
      # make sure there are actually days selected
      if params[:black_out][:days].first.blank?
        flash[:error] = 'You must select at least one day of the week for any recurring blackouts to be created.'
        return
      end

      if params[:black_out][:black_out_type] != 'hard' && params[:black_out][:black_out_type] != 'soft'
        flash[:error] = 'Please select a blackout type.'
        return
      end

      if params[:black_out][:notice] == ''
        flash[:error] = 'Please provide a short description of the blackout.'
        return
      end
    end
end
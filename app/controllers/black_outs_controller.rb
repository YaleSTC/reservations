class BlackOutsController < ApplicationController

  before_filter :require_admin

  def index
    @black_outs = BlackOut.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @black_outs }
    end
  end

  def show
    @black_out = BlackOut.find(params[:id])
    unless @black_out.set_id.nil?
      @black_out_set = BlackOut.where("set_id = ?", @black_out.set_id)
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @black_out }
    end
  end

  def new
    @black_out = BlackOut.new
    @black_out[:start_date] = Date.today # Necessary for datepicker functionality
    @black_out[:end_date] = Date.today # Necessary for datepicker functionality

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @black_out }
    end
  end

  def edit
    @black_out = BlackOut.find(params[:id])
  end

  def create
    # correct for date formatting
    params[:black_out][:start_date] = Date.strptime(params[:black_out][:start_date],'%m/%d/%Y')
    params[:black_out][:end_date] = Date.strptime(params[:black_out][:end_date],'%m/%d/%Y')

    # make sure dates are valid
    if params[:black_out][:end_date] < params[:black_out][:start_date]
      flash[:error] = 'Due date must be after the start date.'
      respond_to do |format|
        format.html {redirect_to :back and return}
        format.js {render :action => 'load_custom_errors' and return}
      end
    end

    # set other params
    params[:black_out][:created_by] = current_user[:id] # Last-edited-by is automatically set
    params[:black_out][:equipment_model_id] = 0 # If per-equipment_model blackouts are implemented, delete this line.
    array = []

    if params[:recurring] == "true"
      # make sure there are actually days selected
      if params[:black_out][:days].first.blank?
        flash[:error] = 'You must select at least one day of the week for any recurring blackouts to be created.'

        # exit
        respond_to do |format|
          format.html {redirect_to :back and return}
          format.js {render :action => 'load_custom_errors' and return}
        end
      end

      # create an array of the appropriate dates to create blackouts for
      array = BlackOut.array_of_black_outs(params[:black_out][:start_date], params[:black_out][:end_date], params[:black_out][:days])
    end

    if array.empty?
      params[:black_out][:set_id] = NIL # the blackouts not belonging to a set
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

    else
      # generate a unique id for this blackout date set
      if BlackOut.last.nil?
        params[:black_out][:set_id] = 1
      else
        params[:black_out][:set_id] = BlackOut.last.id + 1
      end

      # save each blackout date
      array.each do |date|
        # set start and end dates for recurring (only single dates)
        params[:black_out][:start_date] = date
        params[:black_out][:end_date] = date

        # save
        @black_out = BlackOut.new(params[:black_out])
        @black_out.save
      end

      # exit
      respond_to do |format|
        format.html { redirect_to black_outs_path, notice: 'Blackouts were successfully created.' }
        format.js { render :action => "create_success" }
      end
    end
  end

  def update
    @black_out = BlackOut.find(params[:id])

    # correct for date formatting
    params[:black_out][:start_date] = Date.strptime(params[:black_out][:start_date],'%m/%d/%Y')
    params[:black_out][:end_date] = Date.strptime(params[:black_out][:end_date],'%m/%d/%Y')

    # make sure dates are valid
    if params[:black_out][:end_date] < params[:black_out][:start_date]
      flash[:error] = 'Due date must be after the start date.'
      redirect_to :back and return
    end

    # set other params
    params[:black_out][:created_by] = current_user[:id] # Last-edited-by is automatically set
    params[:black_out][:equipment_model_id] = 0 # If per-equipment_model blackouts are implemented, delete this line.

    # do not leave a recurring set with one element
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
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @black_out.errors, status: :unprocessable_entity }
      end
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

  def destroy
    @black_out = BlackOut.find(params[:id])
    @black_out.destroy(:force)

    respond_to do |format|
      format.html { redirect_to black_outs_url }
      format.json { head :no_content }
    end
  end

  def destroy_recurring
    @black_out = BlackOut.find(params[:id])
    black_out_set = BlackOut.where("set_id = ?", @black_out.set_id)
    black_out_set.each do |black_out|
      black_out.destroy(:force)
    end

    # exit
    flash[:notice] = "All blackouts in the set were successfully destroyed."
    redirect_to black_outs_path and return
  end

end

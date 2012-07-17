class BlackOutsController < ApplicationController

  before_filter :require_admin  

  # GET /black_outs
  # GET /black_outs.json
  def index
    @black_outs = BlackOut.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @black_outs }
    end
  end

  # GET /black_outs/1
  # GET /black_outs/1.json
  def show
    @black_out = BlackOut.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @black_out }
    end
  end

  # GET /black_outs/new
  # GET /black_outs/new.json
  def new
    @black_out = BlackOut.new
    @black_out[:start_date] = Date.today #Necessary for datepicker functionality
    @black_out[:end_date] = Date.today #Necessary for datepicker functionality

    respond_to do |format|
      if request.path == recurring_black_out_path
        format.html{render "new_recurring"}
      else
        format.html # new.html.erb
      end
      format.json { render json: @black_out }
    end
  end

  # GET /black_outs/1/edit
  def edit
    @black_out = BlackOut.find(params[:id])
  end

  # POST /black_outs
  # POST /black_outs.json
  def create
    # correct for date formatting
    params[:black_out][:start_date] = Date.strptime(params[:black_out][:start_date],'%m/%d/%Y')
    params[:black_out][:end_date] = Date.strptime(params[:black_out][:end_date],'%m/%d/%Y')
    
    # make sure dates are valid
    if params[:black_out][:end_date] < params[:black_out][:start_date]
      flash[:error] = 'Due date must be after the start date.'
      redirect_to :back and return
    end

    # set other params
    params[:black_out][:created_by] = current_user[:id] #Last-edited-by is automatically set
    params[:black_out][:equipment_model_id] = 0 #If per-equipment_model blackouts are implemented, delete this line.
    array = []

    if params[:recurring] == "true"
      # make sure there are actually days selected
      if params[:days].empty? # TODO do we need to first check NIL?, to avoid errors if none selected?
        flash[:error] = 'Must select at least one day of the week for the recurring black outs.'
        redirect_to :back and return
      end
      
      # create an array of the appropriate dates to create blackouts for
      array = BlackOut.array_of_black_outs(params[:black_out][:start_date], params[:black_out][:end_date], params[:days])
    end

    if array.empty?
      params[:black_out][:set_id] = NIL # the black outs not belonging to a set
      @black_out = BlackOut.new(params[:black_out])
      
      # save and exit
      respond_to do |format|
        if @black_out.save
          format.html { redirect_to @black_out, notice: 'Black out was successfully created.' }
          format.json { render json: @black_out, status: :created, location: @black_out }
        else
          format.html { render action: "new" }
          format.json { render json: @black_out.errors, status: :unprocessable_entity }
        end
      end
    else
      # generate a unique id for this blackout date set
      if BlackOut.last.nil? # TODO make sure this works
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
        if @black_out.save
          format.html { redirect_to black_outs_path, notice: 'Black out was successfully created.' }
#          format.json { render json: @black_out, status: :created, location: @black_out }
        else
          format.html { render action: "new" }
#          format.json { render json: @black_out.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /black_outs/1
  # PUT /black_outs/1.json
  def update
    @black_out = BlackOut.find(params[:id])

    params[:black_out][:start_date] = Date.strptime(params[:black_out][:start_date],'%m/%d/%Y')
    params[:black_out][:end_date] = Date.strptime(params[:black_out][:end_date],'%m/%d/%Y')
    params[:black_out][:created_by] = current_user[:id] #Last-edited-by is automatically set
    params[:black_out][:equipment_model_id] = 0 #If per-equipment_model blackouts are implemented, delete this line.
    
    # make sure dates are valid
    if params[:black_out][:end_date] < params[:black_out][:start_date]
      flash[:error] = 'Due date must be after the start date.'
      redirect_to :back and return
    end


    respond_to do |format|
      if @black_out.update_attributes(params[:black_out])
        format.html { redirect_to @black_out, notice: 'Black out was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @black_out.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /black_outs/1
  # DELETE /black_outs/1.json
  def destroy
    @black_out = BlackOut.find(params[:id])
    @black_out.destroy(:force)

    respond_to do |format|
      format.html { redirect_to black_outs_url }
      format.json { head :no_content }
    end
  end

end

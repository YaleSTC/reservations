class BlackoutsController < ApplicationController

  load_and_authorize_resource
  before_action :set_current_blackout, only: [:edit, :show, :update, :destroy, :destroy_recurring]


  # ---------- before filter methods ------------ #

  def set_current_blackout
    @blackout = Blackout.find(params[:id])
  end

  # ---------- end before filter methods ------------ #

  def index
    @blackouts = Blackout.all
  end

  def show
    unless @blackout.set_id.nil?
      @blackout_set = Blackout.where("set_id = ?", @blackout.set_id)
    end
  end

  def new
    @blackout = Blackout.new(start_date: Date.current, end_date: Date.tomorrow)
  end

  def new_recurring
    @blackout = Blackout.new(start_date: Date.current, end_date: Date.tomorrow)
  end

  def edit
  end

  def create_recurring
    # called when a recurring blackout is needed
    # this class method will parse the params hash
    # and create separate blackouts on each appropriate date

    @blackout = Blackout.new(blackout_params) # for the form if there are errors

    if params[:blackout][:days].first.blank?
      flash[:error] = 'You must select at least one day of the week for any recurring blackouts to be created.'
      render 'new_recurring' and return
    end

    render 'new_recurring' and return unless @blackout.valid?

    p = blackout_params
    p[:created_by] = current_user.id

    # method will return an error message if save is not successful
    flash[:error] = Blackout.create_blackout_set(p, params[:blackout][:days])
    # if there is an error, show it and redirect :back
    if flash[:error]
      render 'new_recurring'
    else
      redirect_to blackouts_path, notice: 'Blackouts were successfully created.'
    end
  end

  def create
    # create a non-recurring blackout
    p = blackout_params
    p[:created_by] = current_user.id
    @blackout = Blackout.new(p)

    # check for conflicts
    res = Reservation.ends_on_days(p[:start_date], p[:end_date])

    # save and exit
    if res.empty? && @blackout.save
      redirect_to @blackout, notice: 'Blackout was successfully created.'
    else
      unless res.empty?
        msg = "The following reservations will be unable to be returned:"
        res.each do |res|
          "\n#{res.md_link}"
        end
      else
        msg = "Oops, something went wrong. Please try again."
      end

      flash[:error] = msg
      render action: 'new'
    end
  end

  def update
    @blackout.set_id = nil
    if @blackout.update_attributes(blackout_params)
      redirect_to @blackout, notice: 'Blackout was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @blackout.destroy(:force)
    redirect_to blackouts_url
  end

  def destroy_recurring
    blackout_set = Blackout.where("set_id = ?", @blackout.set_id)
    blackout_set.each do |blackout|
      blackout.destroy(:force)
    end
    flash[:notice] = "All blackouts in the set were successfully destroyed."
    redirect_to blackouts_path and return
  end

  private
    def blackout_params
      params.require(:blackout).permit(:start_date, :end_date, :notice, :blackout_type, :created_by, :set_id)
    end
end

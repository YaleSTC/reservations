# frozen_string_literal: true

class BlackoutsController < ApplicationController
  load_and_authorize_resource
  before_action :set_current_blackout,
                only: %i[edit show update destroy destroy_recurring]

  # ---------- before filter methods ------------ #

  def set_current_blackout
    @blackout = Blackout.find(params[:id])
  end

  # ---------- end before filter methods ------------ #

  def index
    @blackouts = Blackout.all
  end

  def show
    return if @blackout.set_id.nil?
    @blackout_set = Blackout.where('set_id = ?', @blackout.set_id)
  end

  def new
    @blackout = Blackout.new(start_date: Time.zone.today,
                             end_date: Time.zone.today + 1.day)
  end

  def new_recurring
    @blackout = Blackout.new(start_date: Time.zone.today,
                             end_date: Time.zone.today + 1.day)
  end

  def edit; end

  def create_recurring
    # called when a recurring blackout is needed
    # this class method will parse the params hash
    # and create separate blackouts on each appropriate date

    @blackout = Blackout.new(blackout_params) # for the form if there are errors

    if params[:blackout][:days].reject(&:blank?).empty?
      flash[:error] = 'You must select at least one day of the week for any '\
      'recurring blackouts to be created.'
      render('new_recurring') && return
    end

    render('new_recurring') && return unless @blackout.valid?

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
    res = Reservation.affected_by_blackout(@blackout).active

    # save and exit
    if res.empty? && @blackout.save
      redirect_to @blackout, notice: 'Blackout was successfully created.'
    else
      if res.empty?
        msg = 'Oops, something went wrong. Please try again.'
      else
        msg = 'The following reservation(s) will be unable to be returned: '
        res.each do |res2|
          msg += "#{res2.md_link}, "
        end
        msg = msg[0, msg.length - 2]\
            + '. Please update their due dates and try again.'
      end

      flash[:error] = msg
      render action: 'new'
    end
  end

  def update
    @blackout.set_id = nil
    updater = BlackoutUpdater.new(blackout: @blackout,
                                  params: blackout_params)
    result = updater.update

    if result[:error]
      flash[:error] = result[:error]
      render action: 'edit'
    else
      redirect_to @blackout, notice: result[:result]
    end
  end

  def destroy
    @blackout.destroy
    redirect_to blackouts_url
  end

  def destroy_recurring
    blackout_set = Blackout.where('set_id = ?', @blackout.set_id)
    blackout_set.each(&:destroy)
    flash[:notice] = 'All blackouts in the set were successfully destroyed.'
    redirect_to(blackouts_path) && return
  end

  private

  def blackout_params
    params.require(:blackout)
          .permit(:start_date, :end_date, :notice, :blackout_type, :created_by,
                  :set_id)
  end
end

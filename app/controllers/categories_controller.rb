class CategoriesController < ApplicationController

  before_filter :require_admin
  before_filter :set_current_category, :only => [:show, :edit, :update, :destroy]
  skip_before_filter :require_admin, :only => [:index, :show]

  include ActivationHelper

  # --------- before filter methods -------- #
  def set_current_category
    @category = Category.find(params[:id])
  end
  # --------- end before filter methods -------- #

  def index
    if (params[:show_deleted])
      @categories = Category.all
    else
      @categories = Category.active
    end
  end

  def show
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(params[:category])
    @category.sort_order = params[:category][:sort_order].to_i
    if @category.save
      flash[:notice] = "Successfully created category."
      redirect_to @category
    else
      flash[:error] = "Oops! Something went wrong with creating the category."
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @category.sort_order = params[:category][:sort_order].to_i
    if @category.update_attributes(params[:category])
      flash[:notice] = "Successfully updated category."
      redirect_to @category
    else
      render :action => 'edit'
    end
  end

  def destroy
    @category.destroy(:force)
    flash[:notice] = "Successfully destroyed category."
    redirect_to categories_url
  end
end

class CategoriesController < ApplicationController
  before_filter :require_admin
  skip_before_filter :require_admin, :only => [:index, :show]
  require 'activationhelper'
  include ActivationHelper

  def index
    if (params[:show_deleted])
      @categories = Category.all
    else
      @categories = Category.active
    end
  end

  def show
    @category = Category.find(params[:id])
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
    @category = Category.find(params[:id])
  end

  def update
    @category = Category.find(params[:id])
    @category.sort_order = params[:category][:sort_order].to_i
    if @category.update_attributes(params[:category])
      flash[:notice] = "Successfully updated category."
      redirect_to @category
    else
      render :action => 'edit'
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy(:force)
    flash[:notice] = "Successfully destroyed category."
    redirect_to categories_url
  end
end

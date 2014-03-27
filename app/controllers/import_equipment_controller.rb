class ImportEquipmentController < ApplicationController
  include CsvImport

  before_filter :require_admin

  def import
  end

  def import_page
  end

  private


end

# frozen_string_literal: true
module ReportsHelper
  require 'csv'
  def generate_report_csv_helper(table, name = 'Reservation Set')
    CSV.generate do |csv|
      csv << [name.titleize] + table.columns.collect(&:name)
      table.rows.each do |row|
        csv << [row.name] + row.data
      end
    end
  end

  def reports_active_tab(key)
    return 'active' if key == :equipment_models
  end
end

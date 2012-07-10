module ReportsHelper
  require 'csv'
  def generate_report_csv_helper(table, name = "Reservation Set")
    CSV.generate do |csv| 
      csv << [name.titleize] + table[:col_names]
      table[:rows].each do |row|
        csv << [row.name] + row.data
      end
    end
  end
end
module ReportsHelper
  require 'csv'
  def generate_report_csv_helper(table)
    CSV.generate do |csv| 
      csv << ["Reservation Set"] + @table_col_names
      table.each do |row|
        csv << [row.name] + row.data
      end
    end
  end
end
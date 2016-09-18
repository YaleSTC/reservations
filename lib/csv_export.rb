# frozen_string_literal: true
module CsvExport
  require 'csv'
  require 'zip'

  PROTECTED_COLS = %w(id encrypted_password reset_password_token
                      reset_password_sent_at).freeze

  # generates a csv from the given model data
  # columns is optional; defaults to all columns except protected
  def generate_csv(data, columns = [])
    columns = data.first.attributes.keys if columns.empty?

    PROTECTED_COLS.each { |col| columns.delete(col) }

    CSV.generate(headers: true) do |csv|
      csv << columns

      data.each do |o|
        csv << columns.map do |attr|
          s = o.send(attr)
          s.is_a?(ActiveRecord::Base) ? s.name : s
        end
      end
    end
  end

  # generates a zip file containing multiple CSVs
  # expects tables to be an array of arrays with the following format:
  # [[objects, columns], ...]
  # where columns is optional; defaults to all columns except protected
  def generate_zip(tables)
    # create the CSVs
    csvs = tables.map { |model| generate_csv(*model) }

    Zip::OutputStream.write_buffer do |stream|
      csvs.each_with_index do |csv, i|
        model_name = tables[i].first.first.class.name
        stream.put_next_entry "#{model_name}_#{Time.zone.now.to_s(:number)}.csv"
        stream.write csv
      end
    end.string
  end

  # downloads a csv of the given model table
  # NOTE: this method depends on ActionController
  def download_csv(data, columns, filename)
    send_data(generate_csv(data, columns),
              filename: "#{filename}_#{Time.zone.now.to_s(:number)}.csv")
  end

  # downloads a zip file containing multiple CSVs
  # expects tables to be an array of arrays with the following format:
  # [[objects, columns], ...]
  # where columns is optional; defaults to all columns except protected
  # NOTE: this method depends on ActionController
  def download_zip(tables, filename)
    send_data(generate_zip(tables), type: 'application/zip',
                                    filename: "#{filename}.zip")
  end

  # NOTE: this method depends on ActionController
  def download_equipment_data(cats: Category.all, models: EquipmentModel.all,
                              items: EquipmentItem.all)
    c = [cats, %w(name max_per_user max_checkout_length max_renewal_times
                  max_renewal_length renewal_days_before_due sort_order)]
    m = [models, %w(category name description late_fee replacement_fee
                    max_per_user max_renewal_length)]
    i = [items, %w(equipment_model name serial)]
    download_zip([c, m, i], "EquipmentData_#{Time.zone.now.to_s(:number)}")
  end
end

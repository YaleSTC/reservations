class SetSaneConfigDefaults < ActiveRecord::Migration
  def change
    config = AppConfig.first
    columns(:app_configs).each do |col|
      if (col.type == :string || col.type == :text) && !(col.name.include? 'favicon')
        # prevent nil strings/text and replace with empty string
        change_column_null(:app_configs, col.name.to_s, false, '')
      end
    end
  end
end

class SetSaneConfigDefaults < ActiveRecord::Migration
  def change
    config = AppConfig.first
    columns(:app_configs).each do |col|
      if col.type == :string && !(col.name.include? 'favicon')
        # set default for all string-type columns
        change_column_default(:app_configs, col.name.to_s, '')
        if config && config.send(col.name).nil?
          # if configs are already set but parameter is nil, set to empty
          # string
          config.send(col.name+'=', '')
          config.save!
        end
      end
    end
  end
end

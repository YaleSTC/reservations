class SetDefaultViewModeToNormal < ActiveRecord::Migration
  def change
    change_column :users, :view_mode, :string, :default => 'normal'
  end
end

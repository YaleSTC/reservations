class ChangeFieldsToDates < ActiveRecord::Migration
  def up
    # changing all of these columns to :date types
    change_column :announcements, :starts_at, :date
    change_column :announcements, :ends_at, :date
    change_column :reservations, :start_date, :date
    change_column :reservations, :due_date, :date
  end

  def down
    # changing all of these columns to :datetime types as they were before
    # since the up method is "lossy", the resulting database won't be identical
    # but that's acceptable since we only care about dates anyway
    change_column :announcements, :starts_at, :datetime
    change_column :announcements, :ends_at, :datetime
    change_column :reservations, :start_date, :datetime
    change_column :reservations, :due_date, :datetime
  end
end

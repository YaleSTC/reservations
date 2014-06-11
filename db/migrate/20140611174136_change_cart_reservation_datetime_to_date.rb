class ChangeCartReservationDatetimeToDate < ActiveRecord::Migration
	def change
		add_column :cart_reservations, :start, :date
		add_column :cart_reservations, :due, :date
		
end

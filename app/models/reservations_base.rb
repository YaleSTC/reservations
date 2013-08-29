module ReservationsBase

  def self.included(base)
    base.belongs_to :equipment_model
    base.belongs_to :reserver, :class_name => 'User'
    base.attr_accessible :reserver, :reserver_id, :start_date, :due_date,
                         :equipment_model_id
    base.validates :reserver, :start_date, :due_date, :presence => true
  end
  
  def duration
  	due_date.to_date - start_date.to_date + 1
  end

end
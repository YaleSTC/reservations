class BlackOut < ActiveRecord::Base

  belongs_to :equipment_model
  attr_accessible :start_date, :end_date, :notice, :equipment_model_id, :black_out_type, :created_by
 
  def self.date_is_blacked_out(date)
    unless (BlackOut.where(:equipment_model_id => 0).where(:start_date => date).empty?) &&  (BlackOut.where(:equipment_model_id => 0).where(:end_date => date).empty?)
      return true
    end
    return false
  end
end

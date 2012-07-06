class BlackOut < ActiveRecord::Base

  belongs_to :equipment_model
  attr_accessible :start_date, :end_date, :notice, :equipment_model_id, :black_out_type, :created_by
 
  def self.date_is_blacked_out(date)
    BlackOut.all.each do |black_out|
       if (black_out[:start_date] .. black_out[:end_date]).cover?(date)
        return black_out
       end
    end
    return false
  end

  
end

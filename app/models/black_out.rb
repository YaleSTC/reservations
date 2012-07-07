class BlackOut < ActiveRecord::Base

  belongs_to :equipment_model
  attr_accessible :start_date, :end_date, :notice, :equipment_model_id, :black_out_type, :created_by
 
  def self.date_is_blacked_out(date) #Returns the black_out object that blacks out the day if the day is blacked out. Otherwise, returns nil.
     BlackOut.all.each do |black_out|
       if ((black_out.start_date..black_out.end_date).cover?(date))
         return black_out
       end
     end
    return nil
  end
  
  def black_out_type_is_hard
     if self.black_out_type == "hard"
       true
     else
       false
     end
  end

  
end

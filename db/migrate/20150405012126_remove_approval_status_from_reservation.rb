class RemoveApprovalStatusFromReservation < ActiveRecord::Migration
  # for use in the flag_res method, based off of Reservation model in v5.5.0
  FLAGS = { request: (1 << 1), missed_email_sent: (1 << 5) }

  # similarly, based off the Reservation model enums in v5.5.0
  STATUSES =
    %w(requested reserved denied checked_out missed returned archived)
      .each_with_index.to_h

  def change
    # store ActiveRecord connection to run queries
    conn = ActiveRecord::Base.connection

    # go through all reservations
    conn.exec_query('select * from reservations').each do |res|
      new_flags = res['flags']
      if res['approval_status'] == 'approved'
        new_flags = flag_res(new_flags, :request)
      elsif res['approval_status'] == 'missed_and_emailed'
        new_flags = flag_res(new_flags, :missed_email_sent)
      end

      if res['checked_in']
        new_status = STATUSES['returned']
        if Time.zone.at(res['checked_in']) >
          (res['due_date'] + 1.day).beginning_of_day
          new_overdue = true
        end
        if res['notes'].try(:include?, 'Archived')
          new_status = STATUSES['archived']
        end
      elsif res['checked_out']
        new_status = STATUSES['checked_out']
        if (res['due_date'] + 1.day).beginning_of_day < Time.zone.today
          new_overdue = true
        end
      elsif res['start_date'].beginning_of_day < Time.zone.today
        new_status = STATUSES['missed']
      elsif res['approval_status'] == 'requested'
        new_flags = flag_res(new_flags, :request)
        new_status = STATUSES['requested']
      elsif res['approval_status'] == 'denied'
        new_flags = flag_res(new_flags, :request)
        new_status = STATUSES['denied']
      elsif 'approved auto'.include? res['approval_status']
        new_status = STATUSES['reserved']
      else
        # catch any unusual reservations
        new_flags = flag_res(new_flags, :request)
        new_status = STATUSES['requested']
      end

      # see if the flags actually changed
      new_flags = (new_flags == res['flags']) ? nil : new_flags

      # make sure we have something to update
      if new_status || new_flags || new_overdue
        update_str = 'UPDATE reservations SET'
        update_str << " status = '#{new_status}'" if new_status
        if new_flags
          update_str << "#{new_status ? ',' : ''} flags = #{new_flags}"
        end
        if new_overdue
          update_str << "#{(new_status || new_flags) ? ',' : ''} overdue = 1"
        end
        update_str << " WHERE reservations.id = #{res['id']}"

        # actually run update
        conn.execute(update_str)
      end
    end

    remove_column :reservations, :approval_status, :string
  end

  # based on the Reservation#flag instance method in v5.5.0 - this allows us to
  # decouple the migration from the actual model
  def flag_res(old_flags, new_flag)
    old_flags | FLAGS[new_flag]
  end
end

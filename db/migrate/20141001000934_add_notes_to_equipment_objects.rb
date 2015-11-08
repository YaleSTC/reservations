class AddNotesToEquipmentObjects < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      add_column :equipment_objects, :notes, :text, limit: 16_777_215, null: false

      # store ActiveRecord connection to run queries
      conn = ActiveRecord::Base.connection

      # go through all equipment items
      conn.exec_query('select * from equipment_objects').each do |ei|
        # set up initial note string
        new_notes = "#### Created at #{ei['created_at'].to_s(:long)}"
        # go through all reservations and prepend to note string as needed
        conn.exec_query('SELECT reservations.* FROM reservations WHERE '\
          "(equipment_object_id = #{ei['id']}) ORDER BY start_date, "\
          'due_date, reserver_id, checked_out DESC').each do |res|

          # get reserver
          reserver = get_user(res['reserver_id'])

          if res['checked_out']
            # get checkout handler
            checkout_handler = get_user(res['checkout_handler_id'])

            new_notes.prepend("#### Checked out (##{res['id']}) by "\
              "#{checkout_handler['first_name']} "\
              "#{checkout_handler['last_name']} for "\
              "#{reserver['first_name']} #{reserver['last_name']} on "\
              "#{res['checked_out'].to_s(:long)}.\n\n")
          end

          if res["checked_in"]
            # get checkin handler
            checkin_handler = get_user(res['checkin_handler_id'])

            new_notes.prepend("#### Checked in (##{res['id']}) by "\
              "#{checkin_handler['first_name']} "\
              "#{checkin_handler['last_name']} for "\
              "#{reserver['first_name']} #{reserver['last_name']} on "\
              "#{res['checked_in'].to_s(:long)}.\n\n")
          end

          # update equipment item with new notes
          conn.execute('UPDATE equipment_objects SET notes = '\
            "'#{new_notes.gsub("'", %q(\\\'))}', "\
            "updated_at = '#{Time.now.utc.strftime('%F %T')}' WHERE "\
            "equipment_objects.id = #{ei['id']}")
        end
      end
    end
  end

  def get_user(id=nil, conn=ActiveRecord::Base.connection)
    conn.exec_query("SELECT users.* FROM users WHERE (id = #{id})").first ||
      { 'first_name' => 'Deleted', 'last_name' => 'User' }
  end
end

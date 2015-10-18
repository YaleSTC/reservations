class AddCasLoginToUsers < ActiveRecord::Migration
  def change
    add_column :users, :cas_login, :string

    # copy username to cas_login if you use CAS already
    if ENV['CAS_AUTH']
      ActiveRecord::Base.connection
        .execute('update users set cas_login=username')
    end
  end
end

require 'bundler/capistrano'

# == DEPLOYMENT DEFAULTS =========
default_domain = ENV['DOMAIN'] ? ENV['DOMAIN'] : "mahi.its.yale.edu"
default_application_prefix = ENV['PREFIX'] ? ENV['PREFIX'] : "reservations_test"
default_branch = ENV['BRANCH'] ? ENV['BRANCH'] : "master"

# == INITIAL CONFIG ==============
set :application, "reservations"
set :repository,  "git://github.com/YaleSTC/reservations.git"
set :apache_config_dir, "/etc/httpd/conf.d"
set :document_root, "/var/www/html"

set :user, "deploy"
set :runner, "deploy"
set :use_sudo, false

set :domain, Capistrano::CLI.ui.ask("Deployment server hostname (default #{default_domain}): ") unless ENV['DOMAIN']
set :application_prefix, Capistrano::CLI.ui.ask("Application prefix (default #{default_application_prefix}): ") unless ENV['PREFIX']
set :branch, Capistrano::CLI.ui.ask("Deployment branch (default #{default_branch}): ") unless ENV['BRANCH']

#Set Variables to default if specified from command line or left blank
set :domain, default_domain if (ENV['DOMAIN'] || fetch(:domain) == "")
set :application_prefix, default_application_prefix if (ENV['PREFIX'] || fetch(:application_prefix) == "")
set :branch, default_branch if (ENV['BRANCH'] || fetch(:branch) == "")

set :deploy_to, "/var/www/rails/#{application}/#{application_prefix}"

set :scm, :git
set :scm_verbose, false

role :app, "#{domain}"
role :web, "#{domain}"
role :db,  "#{domain}", :primary => true


# == CONFIG ====================================================================

namespace :init do
  namespace :config do
    desc "Create database.yml"
    task :database do
      set :mysql_user, Capistrano::CLI.ui.ask("deployment host database user name: ")
      set :mysql_pass, Capistrano::CLI.password_prompt("deployment host database password: ")
      database_configuration =<<-EOF
---
production:
  adapter: mysql2
  database: #{application}_#{application_prefix}_production
  host: localhost
  username: #{mysql_user}
  password: #{mysql_pass}

EOF
      run "mkdir -p #{shared_path}/config"
      put database_configuration, "#{shared_path}/config/database.yml"
    end

    desc "Enter Airbrake API code"
    task :airbrake do
      set :api_key, Capistrano::CLI.ui.ask("Airbrake API Key: ")
      airbrake_config=<<-EOF
Airbrake.configure do |config|
  config.api_key = '#{api_key}'
end
EOF
      put airbrake_config, "#{shared_path}/config/airbrake.rb"
    end

    task :prefix_initializer do
      prefix_config_file =<<-EOF
Reservations::Application.configure do
  config.action_controller.relative_url_root = '/#{application_prefix}'
end
EOF

      run "mkdir -p #{shared_path}/config"
      put prefix_config_file, "#{shared_path}/config/prefix.rb"
    end



    desc "Symlink shared configurations to current"
    task :localize, :roles => [:app] do

      run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/database.yml"
      run "ln -nsf #{shared_path}/config/airbrake.rb #{release_path}/config/initializers/airbrake.rb"
      run "ln -nsf #{shared_path}/config/prefix.rb #{release_path}/config/initializers/prefix.rb"
      run "mkdir -p #{shared_path}/log"
      run "mkdir -p #{shared_path}/pids"
      run "mkdir -p #{shared_path}/sessions"
      run "mkdir -p #{shared_path}/system/datas"

      run "ln -nsfF #{shared_path}/log/ #{release_path}/log"
      run "ln -nsfF #{shared_path}/pids/ #{release_path}/tmp/pids"      
      run "ln -nsfF #{shared_path}/sessions/ #{release_path}/tmp/sessions"
      run "ln -nsfF #{shared_path}/system/ #{release_path}/public/system"
    end    
  end  
end

# == DATABASE ==================================================================
# == BACKUP DB TASK

namespace :db do
  desc "Backup your Database to #{shared_path}/db_backups"
  task :backup, :roles => :db, :only => {:primary => true} do
    set :db_user, Capistrano::CLI.ui.ask("Database user: ")
    set :db_pass, Capistrano::CLI.password_prompt("Database password: ")
    now = Time.now
    run "mkdir -p #{shared_path}/backup"
    backup_time = [now.year,now.month,now.day,now.hour,now.min,now.sec].join('-')
    set :backup_file, "#{shared_path}/backup/#{application}-snapshot-#{backup_time}.sql"
    run "mysqldump --add-drop-table -u #{db_user} -p #{db_pass} #{application}_#{application_prefix}_production --opt | bzip2 -c > #{backup_file}.bz2"
  end

end

#== DEPLOYMENT
#=====================================================================

#before "deploy:migrate", "db:backup"
namespace :deploy do

  desc "Initializer. Runs setup, copies code, creates and migrates db, and starts app"
  task :first, :roles => :app do
    setup
    create_db
    update
    init.config.localize
    passenger_config
    migrate
    restart_apache
  end

  desc "Create vhosts file for Passenger config"
  task :passenger_config, :roles => :app do
    run "sh -c \'echo \"RailsBaseURI /#{application_prefix}\" > #{apache_config_dir}/rails/rails_#{application}_#{application_prefix}.conf\'"
    run "ln -s #{deploy_to}/current/public #{document_root}/#{application_prefix}"    
  end

  desc "Create database"
  task :create_db, :roles => :app do
    run "mysqladmin --user=root --password=#{mysql_pass} create #{application}_#{application_prefix}_production"
  end

  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  desc "Restart Apache"
  task :restart_apache, :roles => :app do
      run "#{sudo} /etc/init.d/httpd restart"
  end

  desc "Update the crontab file"
  task :update_crontab, :roles => :app do
    run "cd #{release_path} && bundle exec whenever --update-crontab #{application}-#{application_prefix} --set 'rails_root=#{current_path}'"
  end

end

after "deploy:setup", "init:config:database"
after "deploy:setup", "init:config:airbrake"
after "deploy:setup", "init:config:prefix_initializer"
after "deploy:symlink", "init:config:localize"
after "deploy:symlink", "deploy:update_crontab"
after "deploy", "deploy:cleanup"
after "deploy", "init:config:localize"
after "deploy:migrations", "deploy:cleanup"
before "deploy:assets:precompile", "init:config:localize"

Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'airbrake-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end

require 'airbrake/capistrano'

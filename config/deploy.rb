# == INITIAL CONFIG ==============

set :user, "deploy"
set :runner, "deploy"
set :use_sudo, :true

set :domain, Capistrano::CLI.ui.ask("deployment server hostname (e.g. weke.its.yale.edu): ")
set :application, "reservations"
set :application_prefix, Capistrano::CLI.ui.ask("deployment application prefix (e.g. bass): ")
set :deploy_to, "/srv/www/rails/#{application}/#{application_prefix}"


set :repository,  "git@github.com:YaleSTC/reservations.git"
set :scm, :git
#set :deploy_via, :remote_cache
set :scm_verbose, false
set :branch, "master"

role :app, "#{domain}"
role :web, "#{domain}"
role :db,  "#{domain}", :primary => true


# == CONFIG ====================================================================
# == SET UP DB STUFF, MONGREL CONFIG

namespace :init do
  namespace :config do
    desc "Create database.yml"
    task :database do
      set :mysql_user, Capistrano::CLI.ui.ask("deployment host database user name: ")
      set :mysql_pass, Capistrano::CLI.password_prompt("deployment host database password: ")
      database_configuration =<<-EOF
---
production:
  adapter: mysql
  database: #{application}_#{application_prefix}_production
  host: localhost
  user: #{mysql_user}
  password: #{mysql_pass}

EOF
      run "mkdir -p #{shared_path}/config"
      put database_configuration, "#{shared_path}/config/database.yml"
    end


    desc "Symlink shared configurations to current"
    task :localize, :roles => [:app] do
      %w[database.yml].each do |f|
        run "ln -nsf #{shared_path}/config/#{f} #{current_path}/config/#{f}"
      end
      run "mkdir -p #{shared_path}/log"
      run "mkdir -p #{shared_path}/pids"
      run "mkdir -p #{shared_path}/sessions"
      run "mkdir -p #{shared_path}/system/datas"
      run "ln -nsfF #{shared_path}/log/ #{current_path}/log"
      run "ln -nsfF #{shared_path}/pids/ #{current_path}/tmp/pids"      
      run "ln -nsfF #{shared_path}/sessions/ #{current_path}/tmp/sessions"
      run "ln -nsfF #{shared_path}/system/ #{current_path}/public/system"
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
end

after "deploy", "deploy:cleanup"
after "deploy:migrations", "deploy:cleanup"
after "deploy:setup", "init:config:database"
after "deploy:symlink", "init:config:localize"
after "deploy:symlink", "deploy:update_crontab"

namespace :deploy do
  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    run "cd #{release_path} && whenever --update-crontab #{application}-#{application_prefix}"
  end
end
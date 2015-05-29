# config valid only for Capistrano 3.1
lock '3.3.5'

set :application, 'Reservations'
set :repo_url, 'https://github.com/YaleSTC/reservations.git'

# Default branch is :master
set :branch, "#{ENV['GIT_TAG']}"

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "#{ENV['DEPLOY_DIR']}"
set :param_file, "#{ENV['PARAM_FILE']}"

# Set Rails environment
# set, :rails_env, 'production'

# Set rvm stuff
set :rvm_ruby_version, File.read('.ruby-version').strip

# Include whenever recipes
set :whenever_environment, ->{ fetch(:environment) }
set :whenever_command, 'bundle exec whenever'
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:environment)}" }
set :whenever_variables, ->{ "rails_root=#{fetch :release_path}&environment=#{fetch :whenever_environment}" }

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log public/system public/attachments vendor/bundle}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  # see http://tutor.lugolabs.com/articles/14-schedule-rails-tasks-with-whenever-and-capistrano
  desc "Update crontab with whenever"
  task :update_cron do
    on roles(:app) do
      within current_path do
        execute :bundle, :exec, "whenever --update-crontab #{fetch(:application)}"
      end
    end
  end

  before :updated, 'config:env'
  before :updated, 'config:db'
  before :updated, 'config:secrets'
  before :updated, 'config:party_foul'
  after :publishing, :restart
end

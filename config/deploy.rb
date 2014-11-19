# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'Reservations'
set :repo_url, 'https://github.com/YaleSTC/reservations.git'

# Default branch is :master
set :branch, "#{ENV['GIT_TAG']}"

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "#{ENV['DEPLOY_DIR']}"

# Set Rails environment
# set, :rails_env, 'production'

# Set RVM version
set :rvm_ruby_version, '2.1.2'

# include whenever recipes
set :whenever_command, 'bundle exec whenever'
set :whenever_environment, defer { stage }
set :whenever_variables, { "rails_root=#{fetch :release_path}&environment=#{fetch :whenever_environment}" }

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

# configuration tasks
namespace :init do
  namespace :config do

    desc 'Create .env'
    task :env
      execute "cp #{release_path}/.env.example #{release_path}/.env"
    end

    desc 'Create database.yml'
    task :db
      execute "cp #{release_path}/config/database.yml.example.production #{release_path}/config/database.yml"
    end

    desc 'Create party_foul initializer'
    task :party_foul
      execute "cp #{release_path}/config/initializers/party_foul.rb.example #{release_path}/config/initializers/party_foul.rb"
    end
  end
end

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

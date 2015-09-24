require 'capistrano'

# configuration tasks
namespace :config do
  desc 'Create .env'
  task :env do
    on roles(:app) do
      # copy Jenkins/parameter file to .env if it exists
      if test "[ -e #{fetch(:param_file)} ]"
        execute "cp -rf #{fetch(:param_file)} #{release_path}/.env"
      else
        fail Capistrano::Error, 'You must specify a valid parameter file.'
      end
    end
  end

  desc 'Create database.yml'
  task :db do
    on roles(:app) do
      execute "cp #{release_path}/config/database.yml.example.production "\
        "#{release_path}/config/database.yml"
    end
  end

  desc 'Copy secrets.yml'
  task :secrets do
    on roles(:app) do
      execute "cp #{release_path}/config/secrets.yml.example "\
        "#{release_path}/config/secrets.yml"
    end
  end

  desc 'Create party_foul initializer'
  task :party_foul do
    on roles(:app) do
      # check for Party Foul parameter in .env file
      env_lines = File.foreach("#{release_path}/.env")
      if env_lines.grep(/PARTY_FOUL_TOKEN/).length > 0
        # copy initializer
        execute "cp -rf #{release_path}/config/initializers/party_foul.rb"\
          ".example #{release_path}/config/initializers/party_foul.rb"
      end
    end
  end
end

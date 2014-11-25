module EnvHelpers

  # wrapper for modifying the environment variables for specific code
  # see: https://github.com/ScrappyAcademy/rock_candy
  def env_wrapper(envs={})
    # store original environment variables and set new ones
    orig_envs = ENV.select { |k, _| envs.has_key? k }
    envs.each { |k, v| ENV[k] = v }

    # run all the code
    yield
  ensure
    # ensure that we reset the environment for other code
    envs.each{ |k, _| ENV.delete k }
    orig_envs.each { |k, v| ENV[k] = v }
  end
end
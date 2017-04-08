# frozen_string_literal: true
module EnvironmentHandler
  FALSE = [0, '0', false, 'false', nil, ''].freeze

  def env?(var)
    !FALSE.include? ENV[var]
  end
end

# frozen_string_literal: true
class QueryBase
  class << self
    delegate :call, to: :new
  end

  def initialize
    raise NotImplementedError
  end

  def call
    raise NotImplementedError
  end
end

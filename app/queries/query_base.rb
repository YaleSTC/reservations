class QueryBase
  class << self
    delegate :call, to: :new
  end

  def initialize
    fail NotImplementedError
  end

  def call
    fail NotImplementedError
  end
end

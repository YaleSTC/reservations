require 'ostruct'

class Contents < OpenStruct
  include ActiveModel::Validations
  @max_length = 500
  validates :contents, length: { maximum: @max_length }

  class << self
    attr_accessor :max_length
  end
end

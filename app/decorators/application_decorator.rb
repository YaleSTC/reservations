# frozen_string_literal: true
class ApplicationDecorator < Draper::Decorator
  include Draper::LazyHelpers

  def make_deactivate_btn(onclick_str = nil)
    if object.deleted_at
      link_to 'Activate', [:activate, object], class: 'btn btn-success',
                                               method: :put
    else
      link_to 'Deactivate', [:deactivate, object],
              class: 'btn btn-danger', method: :put,
              onclick: onclick_str.to_s
    end
  end
end

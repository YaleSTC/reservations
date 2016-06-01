module ButtonComponents
  def submit_button(*args, &block)
    options = args.extract_options!
    options[:class] = ['btn-primary', options[:class]].compact
    args << options
    # rubocop:disable AssignmentInCondition
    if cancel = options.delete(:cancel)
      submit(*args, &block) + ' ' + template.link_to(
        template.button_tag(I18n.t('simple_form.buttons.cancel'),
                            type: 'button', class: 'btn btn-default'), cancel
      )
    else
      submit(*args, &block)
    end
    # rubocop:enable AssignmentInCondition
  end
end

SimpleForm::FormBuilder.send :include, ButtonComponents

module WrappedButton
  def wrapped_button(*args, &block)
    template.content_tag :div, class: 'form-actions' do
      options = args.extract_options!
      if object.new_record?
        loading = I18n.t('simple_form.creating')
      else
        loading = I18n.t('simple_form.updating')
      end
      options[:"data-loading-text"] =
        [loading, options[:"data-loading-text"]].compact
      options[:class] = ['btn', options[:class]].compact
      args << options
      if cancel == options.delete(:cancel)
        submit(*args, &block) + ' '\
        + template.link_to(
          template.button_tag(I18n.t('simple_form.buttons.cancel'),
                              type: 'button', class: 'btn'), cancel)
      else
        submit(*args, &block)
      end
    end
  end
end
SimpleForm::FormBuilder.send :include, WrappedButton

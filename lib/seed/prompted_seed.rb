# frozen_string_literal: true
# rubocop:disable Rails/Output
module PromptedSeed
  def prompted_seed
    prompt_app_config
    prompt_user

    generate('user')
    generate('category')
    generate('blackout')

    return if Category.count == 0
    puts "\nThis is going to take awhile...\n" unless NO_PICS
    generate('equipment_model')

    return if EquipmentModel.count == 0
    generate('equipment_item')
    generate('requirement')
    generate('checkin_procedure')
    generate('checkout_procedure')

    return if EquipmentItem.count == 0
    generate('reservation')
  end

  private

  def generate(model)
    Generator.generate(model, ask_for_records(model))
  end

  def ask_for_records(model)
    formatted_model = model.camelize

    puts "\nHow many #{formatted_model} records would you like to generate?" \
      '(please enter a number)'
    n = STDIN.gets.chomp
    # set n to 0 if blank, otherwise try to convert to an int.
    # if that fails re-prompt
    n = 0 if n == ''
    n = Integer(n) rescue nil # rubocop:disable RescueModifier
    if n.nil? || n < 0
      puts "Please enter a whole number\n"
      return ask_for_records(model)
    end
    n
  end

  def prompt_field(obj, field)
    puts field.to_s.split('_').collect(&:capitalize).join(' ') + ':'
    obj[field] = STDIN.gets.chomp
    begin
      obj.save!
    rescue ActiveRecord::RecordInvalid => e
      puts e.to_s
      prompt_field(obj, field)
    end
  end

  def prompt_password(user)
    puts 'Temp Password:'
    user.password = STDIN.noecho(&:gets).chomp
    user.password_confirmation = user.password
    begin
      user.save!
    rescue ActiveRecord::RecordInvalid => e
      puts e.to_s
      prompt_password(user)
    end
  end

  def prompt_user
    puts 'We need to create an account for you first.' \
      'Please enter the following info:'
    u = Generator.superuser
    prompt_field(u, :first_name)
    prompt_field(u, :last_name)
    prompt_field(u, :phone)
    prompt_field(u, :email)
    prompt_field(u, :affiliation)
    if ENV['CAS_AUTH']
      prompt_field(u, :cas_login)
      u.username = u.cas_login
      u.save
    else
      u.username = u.email
      u.save
      prompt_password(u)
    end
  end

  def prompt_app_config
    ac = Generator.app_config
    puts 'We need to setup application settings:'
    prompt_field(ac, :admin_email)
    prompt_field(ac, :department_name)
    printf 'The contact form email - '
    prompt_field(ac, :contact_link_location)
    prompt_field(ac, :home_link_text)
    prompt_field(ac, :home_link_location)
    prompt_field(ac, :site_title)
  end
end

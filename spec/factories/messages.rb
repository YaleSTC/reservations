# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message do
    name { generate(:name) }
    email { "#{name}@yale.edu".downcase }
    subject 'Message'
    body 'Typewriter tumblr actually, locavore tofu Etsy kitsch pug next '\
      'level ugh pickled lomo single-origin coffee fingerstache. Echo Park '\
      'Odd Future 3 wolf moon tofu, narwhal wayfarers Portland readymade '\
      'plaid. Intelligentsia occupy Pinterest Bushwick, lomo flannel '\
      'actually meh mumblecore lo-fi ugh. Retro Echo Park next level '\
      'shoreditch typewriter. Godard irony keffiyeh chambray gluten-free, '\
      'YOLO 3 wolf moon swag flannel fap cred sartorial kogi sriracha. '\
      'Tumblr ugh viral keytar, semiotics fingerstache Godard Vice Cosby '\
      'sweater. Forage yr whatever salvia tote bag.'
  end
end

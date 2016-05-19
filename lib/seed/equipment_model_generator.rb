# frozen_string_literal: true
module EquipmentModelGenerator
  IMAGES = Dir.glob(File.join(Rails.root, 'db', 'seed_images', '*'))
  NO_PICS ||= true

  def self.generate
    EquipmentModel.create! do |em|
      em.name = FFaker::Product.product + ' ' + rand(1..9001).to_s
      em.description = FFaker::HipsterIpsum.paragraph(16)
      em.late_fee = rand(50.00..1000.00).round(2).to_d
      em.replacement_fee = rand(50.00..1000.00).round(2).to_d
      em.category = Category.all.sample
      em.max_per_user = rand(1..em.category.max_per_user)
      em.active = true
      em.max_renewal_times = rand(0..40)
      em.max_renewal_length = rand(0..40)
      em.renewal_days_before_due = rand(0..9001)
      em.photo = File.open(IMAGES.sample) unless NO_PICS
      em.associated_equipment_models = EquipmentModel.all.sample(6)
    end
  end
end

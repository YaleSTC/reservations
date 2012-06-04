# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)


categories = Category.create([{:name => "Cameras"}, {:name => "Cables"}])
categories.each {|a| a.save}
cameramodels = EquipmentModel.create([{:name => "Canon 123", :category_id => 1}])
cameramodels.each {|a| a.save}
cablemodels =  EquipmentModel.create([{:name => "USB Cable", :category_id => 2}])
cablemodels.each {|a| a.save}
cameras = EquipmentObject.create([{:name => "blue", :serial => 1233, :cameramodel => cameramodels.first},{:name => "red", :serial => 1234, :cameramodel => cameramodels.first}])
cameras.each {|a| a.save}

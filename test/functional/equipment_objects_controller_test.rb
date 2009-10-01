require 'test_helper'

class EquipmentObjectsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => EquipmentObject.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    EquipmentObject.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    EquipmentObject.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to equipment_object_url(assigns(:equipment_object))
  end
  
  def test_edit
    get :edit, :id => EquipmentObject.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    EquipmentObject.any_instance.stubs(:valid?).returns(false)
    put :update, :id => EquipmentObject.first
    assert_template 'edit'
  end
  
  def test_update_valid
    EquipmentObject.any_instance.stubs(:valid?).returns(true)
    put :update, :id => EquipmentObject.first
    assert_redirected_to equipment_object_url(assigns(:equipment_object))
  end
  
  def test_destroy
    equipment_object = EquipmentObject.first
    delete :destroy, :id => equipment_object
    assert_redirected_to equipment_objects_url
    assert !EquipmentObject.exists?(equipment_object.id)
  end
end

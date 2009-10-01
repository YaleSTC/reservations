require 'test_helper'

class EquipmentModelsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => EquipmentModel.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    EquipmentModel.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    EquipmentModel.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to equipment_model_url(assigns(:equipment_model))
  end
  
  def test_edit
    get :edit, :id => EquipmentModel.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    EquipmentModel.any_instance.stubs(:valid?).returns(false)
    put :update, :id => EquipmentModel.first
    assert_template 'edit'
  end
  
  def test_update_valid
    EquipmentModel.any_instance.stubs(:valid?).returns(true)
    put :update, :id => EquipmentModel.first
    assert_redirected_to equipment_model_url(assigns(:equipment_model))
  end
  
  def test_destroy
    equipment_model = EquipmentModel.first
    delete :destroy, :id => equipment_model
    assert_redirected_to equipment_models_url
    assert !EquipmentModel.exists?(equipment_model.id)
  end
end

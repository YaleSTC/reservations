require 'test_helper'

class ReservationsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => Reservation.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Reservation.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    Reservation.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to reservation_url(assigns(:reservation))
  end
  
  def test_edit
    get :edit, :id => Reservation.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    Reservation.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Reservation.first
    assert_template 'edit'
  end
  
  def test_update_valid
    Reservation.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Reservation.first
    assert_redirected_to reservation_url(assigns(:reservation))
  end
  
  def test_destroy
    reservation = Reservation.first
    delete :destroy, :id => reservation
    assert_redirected_to reservations_url
    assert !Reservation.exists?(reservation.id)
  end
end

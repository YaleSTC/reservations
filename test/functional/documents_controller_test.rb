require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => Document.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Document.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    Document.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to document_url(assigns(:document))
  end
  
  def test_edit
    get :edit, :id => Document.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    Document.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Document.first
    assert_template 'edit'
  end
  
  def test_update_valid
    Document.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Document.first
    assert_redirected_to document_url(assigns(:document))
  end
  
  def test_destroy
    document = Document.first
    delete :destroy, :id => document
    assert_redirected_to documents_url
    assert !Document.exists?(document.id)
  end
end

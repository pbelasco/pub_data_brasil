require 'test_helper'

class PaginasControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:paginas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pagina" do
    assert_difference('Pagina.count') do
      post :create, :pagina => { }
    end

    assert_redirected_to pagina_path(assigns(:pagina))
  end

  test "should show pagina" do
    get :show, :id => paginas(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => paginas(:one).to_param
    assert_response :success
  end

  test "should update pagina" do
    put :update, :id => paginas(:one).to_param, :pagina => { }
    assert_redirected_to pagina_path(assigns(:pagina))
  end

  test "should destroy pagina" do
    assert_difference('Pagina.count', -1) do
      delete :destroy, :id => paginas(:one).to_param
    end

    assert_redirected_to paginas_path
  end
end

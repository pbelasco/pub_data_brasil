require 'test_helper'

class ProposicaosControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:proposicaos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create proposicao" do
    assert_difference('Proposicao.count') do
      post :create, :proposicao => { }
    end

    assert_redirected_to proposicao_path(assigns(:proposicao))
  end

  test "should show proposicao" do
    get :show, :id => proposicaos(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => proposicaos(:one).to_param
    assert_response :success
  end

  test "should update proposicao" do
    put :update, :id => proposicaos(:one).to_param, :proposicao => { }
    assert_redirected_to proposicao_path(assigns(:proposicao))
  end

  test "should destroy proposicao" do
    assert_difference('Proposicao.count', -1) do
      delete :destroy, :id => proposicaos(:one).to_param
    end

    assert_redirected_to proposicaos_path
  end
end

# frozen_string_literal: true

require 'test_helper'

module Users
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @token, digest = Devise.token_generator.generate(User, :reset_password_token)
      @user.update!(reset_password_token: digest, reset_password_sent_at: Time.current)
    end

    test 'rejects a short password without consuming the reset token' do
      put user_password_path, params: { user: { reset_password_token: @token, password: 'Abc12!x',
                                                password_confirmation: 'Abc12!x' } }

      assert_response :unprocessable_entity
      assert @user.reload.valid_password?('password123')
      assert_predicate @user.reset_password_token, :present?
    end

    test 'accepts eight characters with all required categories and consumes the reset token' do
      put user_password_path, params: { user: { reset_password_token: @token, password: 'Teste12!',
                                                password_confirmation: 'Teste12!' } }

      assert_response :redirect
      assert @user.reload.valid_password?('Teste12!')
      assert_nil @user.reset_password_token
    end

    test 'shows password requirements on reset' do
      get edit_user_password_path(reset_password_token: @token)

      assert_select 'input[name="user[password]"][minlength="8"][required]'
      assert_select '#password-requirements', text: /pelo menos 8 caracteres/
    end

    test 'rejects a password without the required categories during reset' do
      put user_password_path, params: { user: { reset_password_token: @token, password: 'teste1234',
                                                password_confirmation: 'teste1234' } }

      assert_response :unprocessable_entity
      assert @user.reload.valid_password?('password123')
      assert_predicate @user.reset_password_token, :present?
    end
  end
end

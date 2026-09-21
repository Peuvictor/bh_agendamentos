require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "rejects passwords shorter than eight characters" do
    user = User.new(email: "password-policy@example.com", password: "Abc12!x")

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
  end

  test "accepts eight characters with all required categories" do
    user = User.new(email: "password-policy@example.com", password: "Teste12!")

    assert_predicate user, :valid?
  end

  test "accepts spaces accents and symbols" do
    user = User.new(email: "password-policy@example.com", password: "Café com pão e sol 1☀")

    assert_predicate user, :valid?
  end

  test "accepts passwords at the bcrypt byte limit" do
    user = User.new(email: "password-policy@example.com", password: "Aa1!#{'é' * 34}")

    assert_predicate user, :valid?
  end

  test "rejects multibyte passwords that bcrypt would truncate" do
    user = User.new(email: "password-policy@example.com", password: "Aa1!#{'é' * 35}")

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_long_in_bytes)
  end

  test "rejects passwords over the character limit" do
    user = User.new(email: "password-policy@example.com", password: "Aa1!#{'a' * 69}")

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_long)
  end

  test "rejects mismatched password confirmation" do
    user = User.new(email: "password-policy@example.com", password: "Teste12!",
                    password_confirmation: "outra frase longa")

    assert_not user.valid?
    assert user.errors.of_kind?(:password_confirmation, :confirmation)
  end

  test "existing accounts can authenticate with their original password" do
    assert users(:one).valid_password?("password123")
  end

  {
    uppercase: "teste123!",
    lowercase: "TESTE123!",
    number: "Testeabc!",
    special_character: "Teste1234",
    special_character_with_space: "Teste123 "
  }.each do |missing_category, password|
    test "rejects password missing #{missing_category}" do
      user = User.new(email: "password-policy@example.com", password: password)

      assert_not user.valid?
      assert_includes user.errors[:password], I18n.t("errors.messages.password_complexity")
    end
  end

  test "recognizes accented uppercase and lowercase letters" do
    user = User.new(email: "password-policy@example.com", password: "Áé12345!")

    assert_predicate user, :valid?
  end
end

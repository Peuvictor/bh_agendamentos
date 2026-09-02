# frozen_string_literal: true

require 'test_helper'

class MailerConfigurationTest < ActiveSupport::TestCase
  test 'uses the Render hostname for links by default' do
    options = MailerConfiguration.default_url_options(
      'RENDER_EXTERNAL_HOSTNAME' => 'bh-agendamentos.onrender.com'
    )

    assert_equal({ host: 'bh-agendamentos.onrender.com', protocol: 'https' }, options)
  end

  test 'allows an explicit host and protocol for links' do
    options = MailerConfiguration.default_url_options(
      'APP_HOST' => 'staging.example.com',
      'MAILER_PROTOCOL' => 'http',
      'RENDER_EXTERNAL_HOSTNAME' => 'ignored.onrender.com'
    )

    assert_equal({ host: 'staging.example.com', protocol: 'http' }, options)
  end

  test 'does not override smtp settings without a configured server' do
    assert_nil MailerConfiguration.smtp_settings({})
  end

  test 'uses the application sender for Devise emails' do
    assert_equal ApplicationMailer.default[:from].call, Devise.mailer_sender
  end

  test 'builds smtp settings from environment values' do
    settings = MailerConfiguration.smtp_settings(
      'APP_HOST' => 'staging.example.com',
      'SMTP_ADDRESS' => 'smtp.example.com',
      'SMTP_PORT' => '2525',
      'SMTP_USERNAME' => 'sandbox-user',
      'SMTP_PASSWORD' => 'sandbox-password',
      'SMTP_AUTHENTICATION' => 'login',
      'SMTP_ENABLE_STARTTLS_AUTO' => 'false'
    )

    assert_equal(
      {
        address: 'smtp.example.com',
        port: 2525,
        domain: 'staging.example.com',
        user_name: 'sandbox-user',
        password: 'sandbox-password',
        authentication: 'login',
        enable_starttls_auto: false
      },
      settings
    )
  end
end

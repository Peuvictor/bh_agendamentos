# frozen_string_literal: true

module MailerConfiguration
  FALSE_VALUES = %w[0 false no off].freeze

  module_function

  def default_url_options(env)
    host = present(env['APP_HOST']) || present(env['RENDER_EXTERNAL_HOSTNAME'])
    return {} unless host

    {
      host: host,
      protocol: present(env['MAILER_PROTOCOL']) || 'https'
    }
  end

  def smtp_settings(env)
    address = present(env['SMTP_ADDRESS'])
    return unless address

    {
      address: address,
      port: smtp_port(env),
      domain: smtp_domain(env)
    }.merge(smtp_authentication(env)).compact
  end

  def smtp_authentication(env)
    {
      user_name: present(env['SMTP_USERNAME']),
      password: present(env['SMTP_PASSWORD']),
      authentication: present(env['SMTP_AUTHENTICATION']) || 'plain',
      enable_starttls_auto: enabled?(env.fetch('SMTP_ENABLE_STARTTLS_AUTO', 'true'))
    }
  end
  private_class_method :smtp_authentication

  def smtp_port(env)
    Integer(present(env['SMTP_PORT']) || '587', 10)
  end
  private_class_method :smtp_port

  def smtp_domain(env)
    present(env['SMTP_DOMAIN']) || default_url_options(env)[:host] || 'localhost'
  end
  private_class_method :smtp_domain

  def present(value)
    value = value.to_s.strip
    value unless value.empty?
  end
  private_class_method :present

  def enabled?(value)
    FALSE_VALUES.none?(value.to_s.strip.downcase)
  end
  private_class_method :enabled?
end

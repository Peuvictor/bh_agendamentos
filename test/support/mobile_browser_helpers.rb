# frozen_string_literal: true

module MobileBrowserHelpers
  def mobile_viewport(width = 390)
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride',
                                    width: width, height: 900, deviceScaleFactor: 1, mobile: false)
  end

  def mobile_login(user, password: 'password123')
    visit new_user_session_path
    fill_in 'E-mail', with: user.email
    fill_in 'Senha', with: password
    click_button 'Entrar'

    assert_current_path(user.admin? ? appointments_path : root_path, wait: 10)
  end

  def set_native_field(label, value)
    field = find_field(label)
    page.execute_script('arguments[0].value = arguments[1]; ' \
                        "arguments[0].dispatchEvent(new Event('change', { bubbles: true }));", field, value)
  end

  def assert_mobile_fit
    page.evaluate_async_script('const done = arguments[0]; requestAnimationFrame(() => requestAnimationFrame(done));')
    dimensions = page.evaluate_script(<<~JS)
      ({ width: document.documentElement.clientWidth, content: document.documentElement.scrollWidth,
         offenders: [...document.querySelectorAll('main *')].filter(el => {
           const r = el.getBoundingClientRect(); return r.width && r.right > innerWidth + 1;
         }).slice(0, 8).map(el => `${el.tagName}.${el.className}`) })
    JS
    assert_operator dimensions['content'], :<=, dimensions['width'] + 1,
                    "Overflow em #{current_path} (#{dimensions['width']}px): #{dimensions['offenders']}"
  end

  def capture_mobile(name)
    # Visual review artifact; contains only fixture data.
    # rubocop:disable-next Lint/Debugger
    page.save_screenshot(Rails.root.join("tmp/screenshots/#{name}.png"))
  end

  def inspect_mobile_pages(paths)
    [320, 390, 768, 1440].each do |width|
      mobile_viewport(width)
      paths.each do |path|
        visit path

        assert_selector 'main'
        assert_mobile_fit
      end
    end
  end
end

# frozen_string_literal: true

module Demo
  class Assets
    FILES = {
      'user/client' => [:avatar, 'marina.png'], 'user/provider' => [:avatar, 'rafael.png'],
      'service/haircut_beard' => [:photo, 'corte-barba.png'], 'service/beard' => [:photo, 'barba.png'],
      'service/haircut' => [:photo, 'corte-classico.png'], 'service/archived' => [:photo, 'corte-barba.png']
    }.freeze

    def call
      FILES.filter_map do |key, (attachment, filename)|
        attach(key, attachment, filename)
        nil
      rescue StandardError => e
        # Do not print provider exception messages, which may contain credentials.
        "#{filename} (#{e.class})"
      end
    end

    private

    def attach(key, attachment, filename)
      model = key.start_with?('user/') ? User : Service
      target = model.find(Records.id(key)).public_send(attachment)
      return if target.attached?

      # Upload before attaching: failed uploads must not leave a broken attachment
      # which would be mistaken for a completed image on the next execution.
      Rails.root.join('db/demo/images', filename).open('rb') do |io|
        target.attach(upload(io, key, filename))
      end
    end

    def upload(io, record_key, filename)
      digest = Digest::MD5.file(io.path)
      key = "demo-v1-#{Records.id(record_key)}-#{digest.hexdigest}"
      # A retry reuses the pending blob and the same storage key, even if the
      # provider accepted the bytes before the previous request timed out.
      blob = ActiveStorage::Blob.find_by(key: key) || ActiveStorage::Blob.create_before_direct_upload!(
        key: key, filename: filename, byte_size: io.size, checksum: digest.base64digest, content_type: 'image/png'
      )
      blob.upload(io, identify: false)
      blob
    end
  end
end

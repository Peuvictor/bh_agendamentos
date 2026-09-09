# frozen_string_literal: true

module DatabaseConcurrencyHelpers
  # Barriers and cleanup stay together so a failed assertion cannot strand a connection.
  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
  def compete(*operations)
    ready = Queue.new
    start = Queue.new
    threads = operations.map do |operation|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          operation.call
        end
      end
    end
    Timeout.timeout(10) { operations.size.times { ready.pop } }
    operations.size.times { start << true }
    yield if block_given?
    Timeout.timeout(15) { threads.map(&:value) }
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
    threads&.each(&:join)
  end

  # Hold one transaction until PostgreSQL confirms the competing connection is waiting.
  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
  def assert_terminal_transition_wins
    appointment = @appointments.first
    original_start = appointment.start_time
    pid_queue = Queue.new
    worker = nil
    appointment.with_lock do
      worker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          pid_queue << connection.select_value('SELECT pg_backend_pid()')
          rescheduler(Appointment.find(appointment.id)).call
        end
      end
      pid = Timeout.timeout(10) { pid_queue.pop }
      wait_for_database_lock(pid)
      yield appointment
    end

    assert_not Timeout.timeout(15) { worker.value }
    assert_equal original_start, appointment.reload.start_time
    assert_empty appointment.reschedulings
  ensure
    worker&.kill if worker&.alive?
    worker&.join
  end

  def wait_for_database_lock(pid)
    Timeout.timeout(10) do
      loop do
        ActiveRecord::Base.connection.execute('SELECT pg_stat_clear_snapshot()')
        waiting = ActiveRecord::Base.connection.select_value(
          "SELECT wait_event_type = 'Lock' FROM pg_stat_activity WHERE pid = #{Integer(pid)}"
        )
        break if waiting

        sleep 0.01
      end
    end
  end
end

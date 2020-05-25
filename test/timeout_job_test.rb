require "test_helper"

class TimeoutJobTest < Minitest::Test

  class Worker
  end

  class TimeoutWorker
    def timeout_in(*args)
      10
    end

    def after_timeout(*args)
      'callback'
    end
  end

  def test_call
    msg = {'args' => 'args'}

    result = TimeoutJob::Middleware.new.call(Worker.new, msg, nil) { 'result' }
    assert result == 'result'

    result = TimeoutJob::Middleware.new.call(TimeoutWorker.new, msg, nil) { 'result' }
    assert result == 'result'
  end

  def test_yield_with_timeout
    timeout_in = TimeoutWorker.new.timeout_in
    result = TimeoutJob::Middleware.new.yield_with_timeout(timeout_in) { 'result' }
    assert result == 'result'
  end

  def test_perform_callback
    args = 'args'
    result = TimeoutJob::Middleware.new.perform_callback(Worker.new, :after_timeout, args)
    assert result.nil?

    args = 'args'
    result = TimeoutJob::Middleware.new.perform_callback(TimeoutWorker.new, :after_timeout, args)
    assert result == 'callback'
  end

  def test_truncate
    result = TimeoutJob::Middleware.new.truncate('a' * 10)
    assert result == 'a' * 10

    result = TimeoutJob::Middleware.new.truncate('a' * 200)
    assert result == 'a' * 100
  end

  def test_logger
  end
end

require 'timeout'
require 'logger'

require "timeout_job/version"

module TimeoutJob
  class Middleware
    def call(worker, msg, queue, &block)
      if worker.respond_to?(:timeout_in)
        result = yield_with_timeout(worker.timeout_in, &block)

        if timeout?
          logger.info "job execution is timed out. timeout_in=#{worker.timeout_in} args=#{truncate(msg['args'].inspect)}"
          perform_callback(worker, :after_timeout, msg['args'])
          nil
        else
          result
        end
      else
        yield
      end
    end

    def yield_with_timeout(timeout_in, &block)
      @timeout = false
      ::Timeout.timeout(timeout_in) do
        yield
      end
    rescue ::Timeout::Error => e
      @timeout = true
      nil
    end

    def timeout?
      @timeout
    end

    def perform_callback(worker, callback_name, args)
      if worker.respond_to?(callback_name)
        parameters = worker.method(callback_name).parameters

        begin
          if parameters.empty?
            worker.send(callback_name)
          else
            worker.send(callback_name, *args)
          end
        rescue ArgumentError => e
          message = "The number of parameters of the callback method (#{parameters.size}) is not the same as the number of arguments (#{args.size})"
          raise ArgumentError.new("#{self.class}:#{worker.class} #{message} callback_name=#{callback_name} args=#{args.inspect} parameters=#{parameters.inspect}")
        end
      end
    end

    def truncate(text, length: 100)
      if text.length > length
        text.slice(0, length)
      else
        text
      end
    end

    def logger
      if defined?(::Sidekiq)
        ::Sidekiq.logger
      elsif defined?(::Rails)
        ::Rails.logger
      else
        ::Logger.new(STDOUT)
      end
    end
  end
end

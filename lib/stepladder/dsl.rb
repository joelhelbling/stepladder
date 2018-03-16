module Stepladder
  class WorkerInitializationError < StandardError; end

  module Dsl
    def source_worker(argument=nil, &block)
      ensure_correct_arity_for!(argument, block)

      series = series_from(argument)
      callable = setup_callable_for(block, series)

      return Worker.new(&callable) if series.nil?

      Worker.new do
        series.each(&callable)

        while true do
          handoff nil
        end
      end

    end

    def relay_worker(&block)
      ensure_regular_arity(block)

      Worker.new do |value|
        value && block.call(value)
      end
    end

    def side_worker(&block)
      ensure_regular_arity(block)

      Worker.new do |value|
        value.tap do |v|
          v && block.call(v)
        end
      end
    end

    def filter_worker(argument=nil, &block)
      if (block && argument.respond_to?(:call))
        throw_with 'You cannot supply two callables'
      end
      callable = argument.respond_to?(:call) ? argument : block
      ensure_callable(callable)

      Worker.new do |value, supply|
        while value && !callable.call(value) do
          value = supply.shift
        end
        value
      end
    end

    def batch_worker(options = {gathering: 1}, &block)
      ensure_regular_arity(block) if block

      Worker.new.tap do |worker|
        worker.instance_variable_set(:@batch_size, options[:gathering])
        worker.instance_variable_set(:@batch_complete_block, block)

        def worker.task(value)
          if value
            @collection = [value]
            until batch_complete?(@collection.last)
              @collection << supply.shift
            end
            @collection.compact
          end
        end

        def worker.batch_complete?(value)
          return true if value.nil?
          if @batch_complete_block
            !! @batch_complete_block.call(value)
          else
            @collection.size >= @batch_size
          end
        end
      end
    end

    def handoff(something)
      Fiber.yield something
    end

    private

    def throw_with(*msg)
      raise WorkerInitializationError.new([msg].flatten.join(' '))
    end

    def ensure_callable(callable)
      unless callable && callable.respond_to?(:call)
        throw_with 'You must supply a callable'
      end
    end

    def ensure_regular_arity(block)
      if block.arity != 1
        throw_with \
          "Worker must accept exactly one argument (arity == 1)"
      end
    end

    # only valid for #source_worker
    def ensure_correct_arity_for!(argument, block)
      return unless block
      if argument
        ensure_regular_arity(block)
      else
        if block.arity > 0
          throw_with \
            'Source worker cannot accept any arguments (arity == 0)'
        end
      end
    end

    def series_from(series)
      return if series.nil?
      case
      when series.respond_to?(:to_a)
        series.to_a
      when series.respond_to?(:scan)
        series.scan(/./)
      else
        [series]
      end
    end

    def setup_callable_for(block, series)
      return block unless series
      if block
        return Proc.new { |value| handoff block.call(value) }
      else
        return Proc.new { |value| handoff value }
      end
    end

  end
end

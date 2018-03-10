module Stepladder
  class WorkerInitializationError < StandardError; end

  module Dsl
    def source(argument=nil, &block)
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

    def filter(argument=nil, &block)
      if (block && argument.respond_to?(:call))
        throw_with 'You cannot supply two callables'
      end
      callable = argument.respond_to?(:call) ? argument : block

      unless callable
        throw_with 'You must supply a callable'
      end
      Worker.new filter: block
    end

    def handoff(something)
      Fiber.yield something
    end

    private

    def throw_with(*msg)
      raise WorkerInitializationError.new([msg].flatten.join(' '))
    end

    def ensure_correct_arity_for!(argument, block)
      return unless block
      if argument
        if block.arity != 1
          throw_with 'Source worker with enumerable argument',
                     'and block must accept exactly one argument',
                     '(arity == 1)'
        end
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

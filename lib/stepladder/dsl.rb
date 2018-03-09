module Stepladder
  class WorkerInitializationError < StandardError; end

  module Dsl
    def filter(argument=nil, &block)
      if (block && argument.respond_to?(:call))
        raise WorkerInitializationError.new("You cannot supply two callables")
      end
      callable = argument.respond_to?(:call) ? argument : block

      unless callable
        raise WorkerInitializationError.new("You must supply a callable")
      end
      Worker.new filter: block
    end

  end
end

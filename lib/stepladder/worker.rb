module Stepladder
  class Worker
    attr_accessor :supplier

    def initialize(p={}, &block)
      @supplier = p[:supplier]
      @filter   = p[:filter] || default_filter
      @task     = block || p[:task] || default_task
      from = caller.first
      def from.handoff(value)
        handoff value
      end
    end

    def product
      work.resume
    end

    def |(subscribing_worker)
      subscribing_worker.supplier = self
      subscribing_worker
    end

    # provided for instance overrides
    def task(value)
      value
    end

    private

    def work
      @my_little_machine ||= Fiber.new do
        loop do
          value = supplier && supplier.product
          if value.nil? || passes_filter?(value)
            handoff @task.call(value)
          end
        end
      end
    end

    def default_task
      Proc.new do |value|
        if task_accepts_a_value?
          task value
        else
          task
        end
      end
    end

    def task_accepts_a_value?
      self.method(:task).arity > 0
    end

    def default_filter
      Proc.new do |value|
        true
      end
    end

    def passes_filter?(value)
      @filter.call value
    end

  end
end

def handoff(product)
  Fiber.yield product
end

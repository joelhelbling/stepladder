module Stepladder
  class Worker
    attr_accessor :supplier

    def initialize(p={}, &block)
      @supplier = p[:supplier]
      @filter   = p[:filter] || default_filter
      @task     = block || p[:task]
      from = caller.first
      def from.handoff(value)
        handoff value
      end
    end

    def product
      if ready_to_work?
        work.resume
      end
    end

    def ready_to_work?
      @task ||= default_task
      raise "This worker's task expects to receive a value from a supplier, but has no supplier." if (task_accepts_a_value? && supplier.nil?)
      true
    end

    def |(subscribing_worker)
      subscribing_worker.supplier = self
      subscribing_worker
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
      if task_method_exists?
        if task_method_accepts_a_value?
          Proc.new { |value| task value }
        else
          Proc.new { task }
        end
      else # no task method, so assuming we have supplier...
        Proc.new { |value| value }
      end
    end

    def task_accepts_a_value?
      @task.arity > 0
    end

    def task_method_exists?
      self.methods.include? :task
    end

    def task_method_accepts_a_value?
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

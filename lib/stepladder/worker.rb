module Stepladder
  class Worker
    attr_accessor :supplier

    def initialize(p={}, &block)
      @supplier = p[:supplier]
      @filter   = p[:filter] || default_filter
      @task     = block || p[:task]
      # don't define default task here
      # because we want to allow for
      # an initialized worker to have
      # a task injected, including
      # method-based tasks.
    end

    def pull
      ensure_ready_to_work!
      workflow.resume
    end

    def ready_to_work?
      @task && (supplier || !task_accepts_a_value?)
    end

    def |(subscribing_worker)
      subscribing_worker.supplier = self
      subscribing_worker
    end

    private

    def ensure_ready_to_work!
      @task ||= default_task
      # at this point we will ensure a task exists
      # because we know that the worker is being
      # asked for product

      unless ready_to_work?
        raise "This worker's task expects to receive a value from a supplier, but has no supplier."
      end
    end

    def workflow
      @my_little_machine ||= Fiber.new do
        loop do
          value = supplier && supplier.pull
          if value.nil? || passes_filter?(value)
            Fiber.yield @task.call(value)
          end
        end
      end
    end

    def default_task
      if task_method_exists?
        if task_method_accepts_a_value?
          Proc.new { |value| self.task value }
        else
          Proc.new { self.task }
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

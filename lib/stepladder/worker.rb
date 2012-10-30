module Stepladder
  class Worker
    attr_accessor :supplier

    def initialize(p={}, &block)
      @supplier = p[:supplier]
      @task     = block || p[:task]
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

    private

    def work
      @my_little_machine ||= Fiber.new do
        loop do
          handoff @task.call(supplier && supplier.product)
        end
      end
    end

  end
end

def handoff(product)
  Fiber.yield product
end

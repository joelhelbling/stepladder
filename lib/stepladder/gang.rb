module Stepladder
  class Gang
    attr_accessor :workers

    def initialize(workers=[])
      link(workers + [])
    end

    def roster
      workers
    end

    def shift
      workers.last.shift
    end

    def ready_to_work?
      workers.first.ready_to_work?
    end

    def supply
      workers.first.supply
    end

    def supply=(source_queue)
      workers.first.supply = source_queue
    end

    def supplies(subscribing_party)
      subscribing_party.supply = self
    end
    alias_method :"|", :supplies

    def roster_push(worker)
      if worker
        worker.supply = @workers.last
        @workers << worker
      end
    end
    alias_method :"<<", :roster_push

    def roster_pop
      workers.pop.tap do |popped|
        popped.supply = nil
      end
    end

    def roster_shift
      workers.shift.tap do
        workers.first.supply = nil
      end
    end

    def roster_unshift(worker)
      workers.first.supply = worker
      workers.unshift worker
    end
    private

    def link(workers)
      @workers = [workers.shift]
      while worker = workers.shift do
        self << worker
      end
    end

  end
end

require 'spec_helper'

module Stepladder
  describe Worker do
    it { should respond_to(:pull, :supplier, :supplier=, :"|") }

    describe "readiness" do
      context "with no supplier" do
        context "with no task" do
          it { should_not be_ready_to_work }
        end
        context "with a task which accepts a value" do
          subject do
            Worker.new { |value| value.to_s }
          end
          it { should_not be_ready_to_work }
        end
        context "with a task which doesn't accept a value" do
          subject do
            Worker.new { "foo" }
          end
          it { should be_ready_to_work }
        end
      end

      context "with a supplier" do
        before do
          subject.supplier = Worker.new { "foofoo" }
        end
        context "with no task" do
          it { should_not be_ready_to_work }
        end
        context "with a task which accepts a value" do
          subject do
            Worker.new { |value| value.upcase }
          end
          it { should be_ready_to_work }
        end
        context "with a task which doesn't accept a value" do
          subject do
            Worker.new { "bar" }
          end
          it { should be_ready_to_work }
        end
      end
    end

    describe "can accept a task" do
      let(:result) { double }
      before do
        result.stub(:copasetic?).and_return(true)
      end

      context "via the constructor" do

        context "as a block passed to ::new" do
          subject do
            Worker.new do
              result
            end
          end

          its(:pull) { should be_copasetic }
        end

        context "as {:task => <proc/lambda>} passed to ::new" do
          let(:callable_task) { Proc.new { result } }

          subject do
            Worker.new task: callable_task
          end

          its(:pull) { should be_copasetic }
        end
      end

      # Note that tasks defined via instance methods will
      # only have access to the scope of the worker.  If
      # you want a worker to have access to a scope outside
      # the worker, use a Proc or Lambda via the constructor
      context "via an instance method" do
        subject { Worker.new }

        context "which accepts an argument" do
          let(:supplier) { double }
          before do
            supplier.stub(:pull).and_return(result)
            subject.supplier = supplier
            def subject.task(value)
              Fiber.yield value
            end
          end
          its(:pull) { should be_copasetic }
        end

        context "or even one which accepts no arguments" do
          before do
            def subject.task
              :copasetic
            end
          end
          its(:pull) { should be :copasetic }
        end
      end

      context "However, when a worker's task accepts an argument," do
        context "but the worker has no supplier," do
          subject { Worker.new { |value| value.do_whatnot } }
          specify "#pull throws an exception" do
            expect { subject.pull }.to raise_error(/has no supplier/)
          end
        end
      end

    end

    describe "= EXAMPLE WORKER TYPES =" do

      let(:source_worker) do
        Worker.new do
          numbers = (1..3).to_a
          while value = numbers.shift
            Fiber.yield value
          end
        end
      end

      let(:relay_worker) do
        Worker.new do |number|
          number && number * 3
        end
      end

      let(:filter) do
        Proc.new do |number|
          number % 2 > 0
        end
      end

      let(:filter_worker) do
        Worker.new filter: filter
      end

      let(:collector_worker) { Worker.new }

      describe "The Source Worker" do
        subject(:the_self_starter) { source_worker }

        it "generates values without a supplier." do
          the_self_starter.pull.should == 1
          the_self_starter.pull.should == 2
          the_self_starter.pull.should == 3
          the_self_starter.pull.should be_nil
        end
      end

      describe "The Relay Worker" do
        before do
          relay_worker.supplier = source_worker
        end

        subject(:triplizer) { relay_worker }

        it "operates on values received from its supplier." do
          triplizer.pull.should == 3
          triplizer.pull.should == 6
          triplizer.pull.should == 9
          triplizer.pull.should be_nil
        end
      end

      describe "The Filter" do
        before do
          filter_worker.supplier = source_worker
        end

        subject(:oddball) { filter_worker }

        it "passes through only select values." do
          oddball.pull.should == 1
          oddball.pull.should == 3
          oddball.pull.should be_nil
        end
      end

      describe "The Collector" do
        before do
          def collector_worker.task(value)
            if value
              @collection = [value]
              while @collection.size < 3
                @collection << supplier.pull
              end
              @collection
            end
          end

          collector_worker.supplier = source_worker
        end

        subject(:collector) { collector_worker }

        it "collects values in threes" do
          collector.pull.should == [1,2,3]
          collector.pull.should be_nil
        end
      end

    end

    describe "#|" do
      Given(:source_worker) { Worker.new { :foo } }
      Given(:subscribing_worker) { Worker.new { |v| "#{v}_bar".to_sym } }

      When(:pipeline) { source_worker | subscribing_worker }

      Then { subscribing_worker.supplier == source_worker }
      Then { pipeline.pull == :foo_bar }
      Then { pipeline == subscribing_worker }
    end

    describe "#pull" do
      Given(:work_product) { :whatever }
      Given { supplier.stub(:pull).and_return(work_product) }
      Given { subject.supplier = supplier }
      Given(:supplier) { double }

      context "resumes a fiber" do
        Given { Fiber.any_instance.should_receive(:resume).and_return(work_product) }

        Then { subject.pull }
      end
    end

  end
end

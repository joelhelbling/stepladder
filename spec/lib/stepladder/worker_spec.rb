require 'spec_helper'
require 'stepladder/worker'

module Stepladder
  describe Worker do
    it { should respond_to(:product, :supplier, :supplier=) }

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

          its(:product) { should be_copasetic }
        end

        context "as {:task => <proc/lambda>} passed to ::new" do
          let(:callable_task) { Proc.new { result } }

          subject do
            Worker.new task: callable_task
          end

          its(:product) { should be_copasetic }
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
            supplier.stub(:product).and_return(result)
            subject.supplier = supplier
            def subject.task(value)
              handoff value
            end
          end
          its(:product) { should be_copasetic }
        end

        context "or even one which accepts no arguments" do
          before do
            def subject.task
              :copasetic
            end
          end
          its(:product) { should be :copasetic }
        end
      end

      context "However, when a worker's task accepts an argument," do
        context "but the worker has no supplier," do
          subject { Worker.new { |value| value.do_whatnot } }
          specify "#product throws an exception" do
            expect { subject.product }.to raise_error(/has no supplier/)
          end
        end
      end

    end

    describe "= WORKER TYPES =" do

      let(:source_worker) do
        Worker.new do
          numbers = (1..3).to_a
          until numbers.empty?
            handoff numbers.shift
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

        it "generates products without a supplier." do
          the_self_starter.product.should == 1
          the_self_starter.product.should == 2
          the_self_starter.product.should == 3
          the_self_starter.product.should be_nil
        end
      end

      describe "The Relay Worker" do
        before do
          relay_worker.supplier = source_worker
        end

        subject(:triplizer) { relay_worker }

        it "operates on values received from its supplier." do
          triplizer.product.should == 3
          triplizer.product.should == 6
          triplizer.product.should == 9
          triplizer.product.should be_nil
        end
      end

      describe "The Filter" do
        before do
          filter_worker.supplier = source_worker
        end

        subject(:oddball) { filter_worker }

        it "passes through only select values." do
          oddball.product.should == 1
          oddball.product.should == 3
          oddball.product.should be_nil
        end
      end

      describe "The Collector" do
        before do
          def collector_worker.task(value)
            if value
              @collection = [value]
              while @collection.size < 3
                @collection << supplier.product
              end
              @collection
            end
          end

          collector_worker.supplier = source_worker
        end

        subject(:collector) { collector_worker }

        it "collects values in threes" do
          collector.product.should == [1,2,3]
          collector.product.should be_nil
        end
      end

      describe "Also, there's a pipeline dsl:" do
        let(:subscribing_worker) { relay_worker }
        let(:pipeline) { source_worker | subscribing_worker }

        subject { pipeline }

        it "lets you daisy-chain workers using \"|\"" do
          subject.inspect
          subscribing_worker.supplier.should == source_worker
        end
      end

    end

    describe "#product" do
      before do
        supplier.stub(:product).and_return(result)
        subject.supplier = supplier
      end
      let(:result)   { :foo }
      let(:supplier) { double }

      it "resumes a fiber" do
        Fiber.any_instance.should_receive(:resume).and_return(result)
        subject.product.should == result
      end
    end

  end
end

require 'spec_helper'
require 'stepladder/worker'

module Stepladder
  describe Worker do
    it { should respond_to(:product, :supplier, :supplier=) }

    # describe "#product" do
    #   before { Fiber.any_instance.stub(:resume).and_return(result) }
    #   let(:result) { :foo }
    #   its(:product) { should == result }
    # end

    describe "different ways to assign a task" do

      context "with a block" do
        subject { Worker.new { :foo } }
        its(:product) { should == :foo }
      end

      context "with a callable :task parameter" do
        let(:callable_task) { Proc.new { :foo } }
        subject { Worker.new task: callable_task }
        its(:product) { should == :foo }
      end

      context "with an instance method" do
        subject { Worker.new }

        context "which accepts an argument" do
          let(:supplier) { double }
          before do
            supplier.stub(:product).and_return(:foo)
            subject.supplier = supplier
            def subject.task(value)
              value
            end
          end
          its(:product) { should == :foo }
        end

        context "or even one which accepts no arguments" do
          before do
            def subject.task
              :foo
            end
          end
          its(:product) { should == :foo }
        end
      end

      context "with task which accepts an argument, but no supplier" do
        subject { Worker.new { |value| value.do_whatnot } }
        it "throws an exception" do
          expect { subject.product }.to raise_error(/has no supplier/)
        end
      end

    end

    describe "worker types" do
      let(:source_worker) do
        Worker.new do
          (1..3).each { |number| handoff number }
          handoff nil
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

      describe "the source" do
        subject { source_worker }

        it "generates products without a supplier" do
          subject.product.should == 1
          subject.product.should == 2
          subject.product.should == 3
          subject.product.should be_nil
        end
      end

      describe "the relay worker" do
        before do
          relay_worker.supplier = source_worker
        end

        subject { relay_worker }

        it "operates on values received from its supplier" do
          subject.product.should == 3
          subject.product.should == 6
          subject.product.should == 9
          subject.product.should be_nil
        end
      end

      describe "the filter" do
        before do
          filter_worker.supplier = source_worker
        end

        subject { filter_worker }

        it "selects only values which match" do
          subject.product.should == 1
          subject.product.should == 3
          subject.product.should be_nil
        end
      end

      describe "pipeline dsl" do
        let(:subscribing_worker) { relay_worker }
        let(:pipeline) { source_worker | subscribing_worker }

        subject { pipeline }

        specify "the subcriber has a supplier" do
          subject.inspect
          subscribing_worker.supplier.should == source_worker
        end
      end

    end
  end
end

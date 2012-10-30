require 'spec_helper'
require 'stepladder/worker'

module Stepladder
  describe Worker do
    it { should respond_to(:product, :supplier, :supplier=) }

    describe "#product" do
      before { Fiber.any_instance.stub(:resume).and_return(result) }
      let(:result) { :foo }
      its(:product) { should == result }
    end

    describe "pipeline dsl" do
      let(:source_worker) do
        Worker.new do
          (1..3).each { |number| handoff number }
        end
      end
      let(:subscribing_worker) do
        Worker.new do |number|
          number * 3
        end
      end
      subject { source_worker | subscribing_worker }

      specify "the subcriber has a supplier" do
        subject.inspect
        subscribing_worker.supplier.should == source_worker
      end

      specify "integration" do
        subject.product.should == 3
      end

    end
  end
end

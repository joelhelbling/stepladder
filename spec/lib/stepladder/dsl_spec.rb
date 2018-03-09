require 'spec_helper'
require 'stepladder/worker'
require 'stepladder/dsl'

module Stepladder
  describe Dsl do
    include Stepladder::Dsl

    Given(:worker) { Worker.new } #placeholder
    Given(:source) do
      Worker.new do
        numbers = (1..3).to_a
        until numbers.empty?
          handoff numbers.shift
        end
      end
    end

    When { source | worker }

    describe '#filter' do
      context 'in normal usage' do
        Given(:worker) do
           filter { |v| v % 2 == 0 }
        end

        Then { worker.product == 2 }
        And { expect(worker.product).to be_nil }
      end
    end

    context 'requires a callable' do
      context 'with no arguments or block' do
        Given(:invocation) { -> { filter } }
        Then { expect(invocation).to raise_error(/supply a callable/) }
      end

      context 'with no callable' do
        Given(:invocation) { -> { filter :foo } }
        Then { expect(invocation).to raise_error(/supply a callable/) }
      end

      context 'with callable arg' do
        Given(:arg) { Proc.new { true } }
        Given(:invocation) { -> { filter arg } }
        Then { expect(invocation).to_not raise_error }
      end

      context 'with both callable arg and block' do
        Given(:arg) { Proc.new { true } }
        Given(:invocation) { -> { filter(arg) do false; end } }
        Then { expect(invocation).to raise_error(/two callables/) }
      end
    end
  end
end

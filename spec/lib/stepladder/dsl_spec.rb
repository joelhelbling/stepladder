require 'spec_helper'
require 'stepladder/worker'
require 'stepladder/dsl'

module Stepladder
  describe Dsl do
    include Stepladder::Dsl

    describe '#source_worker' do
      context 'normal usage' do
        context 'with an array' do
          Given(:worker) { source_worker [:fee, :fi] }

          Then { worker.product == :fee }
          And  { worker.product == :fi }
          And  { worker.product.nil? }
        end

        context 'with a range' do
          Given(:worker) { source_worker (0..2) }

          Then { worker.product == 0 }
          And  { worker.product == 1 }
          And  { worker.product == 2 }
          And  { worker.product.nil? }
        end

        context 'with a string' do
          Given(:worker) { source_worker 'abc' }

          Then { worker.product == 'a' }
          And  { worker.product == 'b' }
          And  { worker.product == 'c' }
          And  { worker.product.nil? }
        end

        context 'with a hash' do
          Given(:worker) { source_worker({foo: 2, bar: 'yarr'}) }

          Then { worker.product == [:foo, 2] }
          And  { worker.product == [:bar, 'yarr'] }
          And  { worker.product.nil? }
        end

        context 'with a anything else' do
          Given(:worker) { source_worker :foo }

          Then { worker.product == :foo }
          And  { worker.product.nil? }
        end

        context 'with a callable' do
          Given(:worker) do
            notes = %i[doh ray me fa so la ti]
            source_worker do
              notes.shift if notes.size > 4
            end
          end

          Then { worker.product == :doh }
          And  { worker.product == :ray }
          And  { worker.product == :me }
          And  { worker.product.nil? }
        end

        context 'with a callable and an argument' do
          Given(:notes) { %i[so la ti] }
          Given(:worker) do
            source_worker notes do |note|
              note.to_s.upcase
            end
          end

          Then { worker.product == 'SO' }
          And  { worker.product == 'LA' }
          And  { worker.product == 'TI' }
          And  { worker.product.nil? }
        end
      end

      context 'illegal usage' do
        context 'with no argument and arity > 0' do
          Given(:invocation) do
            -> { source_worker { |v| v * 2 } }
          end
          Then { expect(invocation).to raise_error(/arity == 0/) }
        end
      end

      context 'with argument' do
        context 'and arity == 0' do
          Given(:invocation) do
            -> { source_worker([]) { :boo } }
          end
          Then { expect(invocation).to raise_error(/arity == 1/) }
        end
        context 'and arity > 1' do
          Given(:invocation) do
            -> { source_worker([]) { |p, q| :boo } }
          end
          Then { expect(invocation).to raise_error(/arity == 1/) }
        end
      end
    end

    describe '#relay_worker' do
      context 'normal usage' do
        Given(:source) { source_worker %w[better stronger faster] }
        Given(:worker) do
          relay_worker { |v| v.gsub(/t/, '+') }
        end

        When { source | worker }

        Then { worker.product == 'be++er' }
        And  { worker.product == 's+ronger' }
        And  { worker.product == 'fas+er' }
        And  { worker.product.nil? }
      end

      context 'illegal usage' do
        context 'arity == 0' do
          Given(:invocation) do
            -> { relay_worker() { :foo } }
          end

          Then { expect(invocation).to raise_error(/arity == 1/) }
        end
      end
    end

    describe '#side_worker' do
      context 'normal usage' do
        Given(:source) { source_worker (0..2) }
        Given(:side_effect) { [] }
        Given(:worker) do
          side_effect
          side_worker { |v| side_effect << v * 2 }
        end

        When { source | worker }

        Then { worker.product == 0 }
        And  { worker.product == 1 }
        And  { worker.product == 2 }
        And  { worker.product.nil? }
        And  { side_effect == [0, 2, 4] }
      end

      context 'illegal usage' do
        context 'arity == 0' do
          Given(:invocation) do
            -> { side_worker() { :foo } }
          end

          Then { expect(invocation).to raise_error(/arity == 1/) }
        end
      end
    end

    describe '#filter_worker' do
      context 'normal usage' do
        Given(:source) { source_worker (1..3) }

        When { source | filter }

        Given(:filter) do
           filter_worker { |v| v % 2 == 0 }
        end

        Then { filter.product == 2 }
        And { expect(filter.product).to be_nil }
      end

      context 'illegal usage' do
        context 'requires a callable' do
          context 'with no arguments or block' do
            Given(:invocation) { -> { filter_worker } }
            Then { expect(invocation).to raise_error(/supply a callable/) }
          end

          context 'with no callable' do
            Given(:invocation) { -> { filter_worker :foo } }
            Then { expect(invocation).to raise_error(/supply a callable/) }
          end

          context 'with callable arg' do
            Given(:arg) { Proc.new { true } }
            Given(:invocation) { -> { filter_worker arg } }
            Then { expect(invocation).to_not raise_error }
          end

          context 'with both callable arg and block' do
            Given(:arg) { Proc.new { true } }
            Given(:invocation) { -> { filter_worker(arg) do false; end } }
            Then { expect(invocation).to raise_error(/two callables/) }
          end
        end
      end
    end
  end
end

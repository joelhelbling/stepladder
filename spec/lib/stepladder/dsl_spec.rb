require 'spec_helper'
require 'stepladder/worker'
require 'stepladder/dsl'

module Stepladder
  describe Dsl do
    include Stepladder::Dsl

    describe '#source' do
      context 'normal usage' do
        context 'with an array' do
          Given(:worker) { source [:fee, :fi] }

          Then { worker.product == :fee }
          And  { worker.product == :fi }
          And  { worker.product.nil? }
        end

        context 'with a range' do
          Given(:worker) { source (0..2) }

          Then { worker.product == 0 }
          And  { worker.product == 1 }
          And  { worker.product == 2 }
          And  { worker.product.nil? }
        end

        context 'with a string' do
          Given(:worker) { source 'abc' }

          Then { worker.product == 'a' }
          And  { worker.product == 'b' }
          And  { worker.product == 'c' }
          And  { worker.product.nil? }
        end

        context 'with a hash' do
          Given(:worker) { source({foo: 2, bar: 'yarr'}) }

          Then { worker.product == [:foo, 2] }
          And  { worker.product == [:bar, 'yarr'] }
          And  { worker.product.nil? }
        end

        context 'with a anything else' do
          Given(:worker) { source :foo }

          Then { worker.product == :foo }
          And  { worker.product.nil? }
        end

        context 'with a callable' do
          Given(:worker) do
            notes = %i[doh ray me fa so la ti]
            source do
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
            source notes do |note|
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
            -> { source { |v| v * 2 } }
          end
          Then { expect(invocation).to raise_error(/arity == 0/) }
        end
      end

      context 'with argument' do
        context 'and arity == 0' do
          Given(:invocation) do
            -> { source([]) { :boo } }
          end
          Then { expect(invocation).to raise_error(/arity == 1/) }
        end
        context 'and arity > 1' do
          Given(:invocation) do
            -> { source([]) { |p, q| :boo } }
          end
          Then { expect(invocation).to raise_error(/arity == 1/) }
        end
      end
    end

    describe '#filter' do
      context 'normal usage' do
        Given(:source) do
          Worker.new do
            numbers = (1..3).to_a
            until numbers.empty?
              handoff numbers.shift
            end
          end
        end

        When { source | filter_worker }

        Given(:filter_worker) do
           filter { |v| v % 2 == 0 }
        end

        Then { filter_worker.product == 2 }
        And { expect(filter_worker.product).to be_nil }
      end

      context 'illegal usage' do
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
  end
end

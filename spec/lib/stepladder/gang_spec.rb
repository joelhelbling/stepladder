require 'spec_helper'

module Stepladder
  describe Gang do
    include DSL

    Given(:source) { source_worker (:a..:z).map(&:to_s) }
    Given(:plusser) { relay_worker { |v| v + '+' } }
    Given(:tilda_er) { relay_worker { |v| v + '~' } }

    When(:gang) { described_class.new workers }

    context 'covers Worker API' do
      it do should respond_to :ready_to_work?, :shift,
                              :supply, :supply=,
                              :supplies, :"|",
                              :roster_pop,
                              :roster_push, :"<<",
                              :roster_shift
      end
    end

    describe '#ready_to_work?' do
      context 'with no source' do
        Given(:workers) { [plusser, tilda_er] }

        Then { expect(gang).to_not be_ready_to_work }
      end

      context 'with an internal source' do
        Given(:workers) { [source, plusser, tilda_er] }

        Then { expect(gang).to be_ready_to_work }
      end

      context 'with external source' do
        context 'supplied to the first worker' do
          Given { source | plusser }
          Given(:workers) { [plusser, tilda_er] }

          Then { expect(gang).to be_ready_to_work }
        end

        context 'supplied to the gang' do
          Given(:workers) { [plusser, tilda_er] }

          When { gang.supply = source }

          Then { expect(gang).to be_ready_to_work }
        end
      end
    end

    describe '#<< (a.k.a. #workers_push)' do
      Given(:workers) { [source, plusser] }

      When { gang << tilda_er }

      Then { gang.shift == 'a+~' }
    end

    describe '#| (a.k.a. #supplies)' do
      Given(:workers) { [source, plusser] }

      When { gang | tilda_er }

      context 'gets gang as source' do
        Then { tilda_er.shift == 'a+~' }
      end

      context 'still works even if rearranging workers' do
        Given(:minuser) { relay_worker { |v| v + '-' } }

        When { gang << minuser }

        Then { tilda_er.shift == 'a+-~' }
      end
    end

    describe '#roster_pop' do
      Given(:workers) { [source, plusser, tilda_er] }

      When(:popped) { gang.roster_pop }

      Then { gang.shift == 'a+' }
      Then { popped == tilda_er }
      Then { popped.supply.nil? }
    end

    describe '#roster_shift' do
      Given(:workers) { [source, plusser, tilda_er] }

      When(:shifted) { gang.roster_shift }

      Then { shifted == source }
      Then { expect(gang).to_not be_ready_to_work }
    end

    describe '#roster_unshift' do
      context 'when first work is not a source' do
        Given(:workers) { [plusser, tilda_er] }

        When { gang.roster_unshift source }

        Then { expect(gang).to be_ready_to_work }
        Then { gang.roster == [source, plusser, tilda_er] }
        Then { gang.shift == 'a+~' }
      end

      context 'when first worker is a source' do
        Given(:new_source) { source_worker (:z..:a).map(&:to_s) }
        Given(:workers) { [source, plusser, tilda_er] }

        Then { expect { gang.roster_unshift new_source }.to raise_error(/cannot accept a supply/) }
      end
    end

    describe '#roster' do
      Given(:workers) { [source, plusser, tilda_er] }

      Then { gang.roster == workers }
    end

    context 'normal usage' do
      Given(:workers) { [source, plusser, tilda_er] }

      Then { gang.shift == 'a+~' }
    end


  end
end


# encoding: utf-8
require 'spec_helper'

describe SEPA::CreditTransferTransaction do
  describe :initialize do
    it 'should initialize a valid transaction' do
      expect(
        SEPA::CreditTransferTransaction.new name:                   'Telekomiker AG',
                                            iban:                   'DE37112589611964645802',
                                            bic:                    'PBNKDEFF370',
                                            amount:                 102.50,
                                            reference:              'XYZ-1234/123',
                                            remittance_information: 'Rechnung 123 vom 22.08.2013'
      ).to be_valid
    end
  end

  describe :schema_compatible? do
    context 'for pain.001.003.03' do
      it 'should succeed' do
        expect(SEPA::CreditTransferTransaction.new({})).to be_schema_compatible('pain.001.003.03')
      end

      it 'should fail for invalid attributes' do
        expect(SEPA::CreditTransferTransaction.new(:currency => 'CHF')).not_to be_schema_compatible('pain.001.003.03')
      end
    end

    context 'pain.001.002.03' do
      it 'should succeed for valid attributes' do
        expect(SEPA::CreditTransferTransaction.new(:bic => 'SPUEDE2UXXX', :service_level => 'SEPA')).to be_schema_compatible('pain.001.002.03')
      end

      it 'should fail for invalid attributes' do
        expect(SEPA::CreditTransferTransaction.new(:bic => nil)).not_to be_schema_compatible('pain.001.002.03')
        expect(SEPA::CreditTransferTransaction.new(:bic => 'SPUEDE2UXXX', :service_level => 'URGP')).not_to be_schema_compatible('pain.001.002.03')
        expect(SEPA::CreditTransferTransaction.new(:bic => 'SPUEDE2UXXX', :currency => 'CHF')).not_to be_schema_compatible('pain.001.002.03')
      end
    end

    context 'for pain.001.001.03' do
      it 'should succeed for valid attributes' do
        expect(SEPA::CreditTransferTransaction.new(:bic => 'SPUEDE2UXXX', :currency => 'CHF')).to be_schema_compatible('pain.001.001.03')
        expect(SEPA::CreditTransferTransaction.new(:bic => nil)).to be_schema_compatible('pain.001.003.03')
      end
    end

    context 'for pain.001.001.03.ch.02' do
      let(:schema) { 'pain.001.001.03.ch.02' }
      context 'payment type 1' do
        let(:type) { { ch_payment_type: '1', ch_local_instrument: 'CH01', currency: 'CHF' } }
        it 'should succeed for valid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ ch_isr_participation_number: '01-123455-2', remittance_reference: '1234567', currency: 'CHF' }.merge(type))).to be_schema_compatible(schema)
        end
        it 'should not succeed for invalid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000', clearing_number: '9000' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_bank_account: '1234', ch_bank_postal_account: '80-2-2', clearing_number: '0230' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_code_line: '> 123124sadfa12312316546483412', ch_bank_postal_account: '80-2-2', creditor_bank_name: 'UBS' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_postal_account: '01-123455-2' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({}.merge(type))).not_to be_schema_compatible(schema)
        end
      end

      context 'payment type 2.1' do
        let(:type) { { ch_payment_type: '2.1', ch_local_instrument: 'CH02', currency: 'CHF' } }
        it 'should succeed for valid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ ch_postal_account: '01-123455-2' }.merge(type))).to be_schema_compatible(schema)
        end
        it 'should not succeed for invalid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000', clearing_number: '9000' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_bank_account: '1234', ch_bank_postal_account: '80-2-2', clearing_number: '0230' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_code_line: '> 123124sadfa12312316546483412', ch_bank_postal_account: '80-2-2', creditor_bank_name: 'UBS' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_isr_participation_number: '01-123455-2', remittance_reference: '1234567' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({}.merge(type))).not_to be_schema_compatible(schema)
        end
      end

      context 'payment type 2.2' do
        let(:type) { { ch_payment_type: '2.2', ch_local_instrument: 'CH03', currency: 'CHF' } }
        it 'should succeed for valid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000', clearing_number: '9000' }.merge(type))).to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_bank_account: '1234', ch_bank_postal_account: '80-2-2', clearing_number: '0230' }.merge(type))).to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_code_line: '> 123124sadfa12312316546483412', ch_bank_postal_account: '80-2-2', creditor_bank_name: 'UBS' }.merge(type))).to be_schema_compatible(schema)
        end
        it 'should not succeed for invalid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_postal_account: '01-123455-2' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_isr_participation_number: '01-123455-2', remittance_reference: '1234567' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({}.merge(type))).not_to be_schema_compatible(schema)
        end
      end

      context 'payment type 3' do
        let(:type) { { ch_payment_type: '3', ch_local_instrument: nil, currency: 'CHF' } }
        it 'should succeed for valid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000' })).to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000' }.merge(type))).to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ iban: 'CH8904835098765432000', clearing_number: '9000' }.merge(type))).to be_schema_compatible(schema)
        end
        it 'should not succeed for invalid attributes' do
          expect(SEPA::CreditTransferTransaction.new({ ch_bank_account: '1234', ch_bank_postal_account: '80-2-2', clearing_number: '0230' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_code_line: '> 123124sadfa12312316546483412', ch_bank_postal_account: '80-2-2', creditor_bank_name: 'UBS' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_postal_account: '01-123455-2' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({ ch_isr_participation_number: '01-123455-2', remittance_reference: '1234567' }.merge(type))).not_to be_schema_compatible(schema)
          expect(SEPA::CreditTransferTransaction.new({}.merge(type))).not_to be_schema_compatible(schema)
        end
      end
    end
  end

  context 'Requested date' do
    it 'should allow valid value' do
      expect(SEPA::CreditTransferTransaction).to accept(nil, Date.new(1999, 1, 1), Date.today, Date.today.next, Date.today + 2, for: :requested_date)
    end

    it 'should not allow invalid value' do
      expect(SEPA::CreditTransferTransaction).not_to accept(Date.new(1995,12,21), Date.today - 1, for: :requested_date)
    end
  end
end

# encoding: utf-8
module SEPA
  class CreditTransferTransaction < Transaction
    CH_LOCAL_INSTRUMENTS = %w(CH01 CH02 CH03)
    CH_PAYMENT_TYPES = %w(1 2.1 2.2 3)

    attr_accessor :service_level
    attr_accessor :ch_payment_type, :ch_local_instrument, :ch_postal_account, :ch_bank_postal_account, :ch_bank_name, :ch_code_line, :ch_bank_account
    convert :ch_payment_type, to: :text

    validate { |t| t.validate_requested_date_after(Date.today) }
    validates_inclusion_of :ch_payment_type, in: CH_PAYMENT_TYPES, allow_nil: true # assume 3 if nil and PAIN_001_001_03_CH_02
    validates_inclusion_of :ch_local_instrument, in: CH_LOCAL_INSTRUMENTS, allow_nil: true

    def initialize(attributes = {})
      self.service_level ||= 'SEPA'
      super
    end

    def schema_compatible?(schema_name)
      case schema_name
      when PAIN_001_001_03
        self.remittance_reference.nil? && self.service_level == 'SEPA'
      when PAIN_001_002_03
        self.remittance_reference.nil? && self.bic.present? && self.service_level == 'SEPA' && self.currency == 'EUR'
      when PAIN_001_003_03
        self.remittance_reference.nil? && self.currency == 'EUR' && %w(SEPA URGP).include?(self.service_level)
      when PAIN_001_001_03_CH_02
        self.service_level = nil # service_level is set by an initializer, where the schema is not known, but must be empty for all supported CH payment types
        valid_base = (self.remittance_information.nil? || self.remittance_reference.nil?) && self.service_level.nil? && %w(EUR CHF).include?(self.currency)
        # see "Swiss Usage Guide" and "Swiss Implementation Guidelines" for pain.001 for details on payment types
        case self.ch_payment_type
        when '1'
          valid_base &&
            self.ch_local_instrument == 'CH01' &&
            self.iban.nil? && self.ch_postal_account.present? && self.reference.present? && self.bic.nil? &&
            self.ch_bank_postal_account.nil? && self.ch_bank_name.nil? && self.ch_code_line.nil?
        when '2.1'
          valid_base &&
            self.ch_local_instrument == 'CH02' &&
            self.iban.nil? && self.ch_postal_account.present? && self.reference.nil? && self.bic.nil? &&
            self.ch_bank_postal_account.nil? && self.ch_bank_name.nil? && self.ch_code_line.nil?
        when '2.2'
          IBANValidator.validate(self) if (self.iban.present? && self.ch_bank_account.nil? && self.ch_code_line.nil?)
          valid_base && self.errors[:iban].empty? &&
            self.ch_local_instrument == 'CH03' &&
            ((self.iban.present? && self.ch_bank_account.nil? && self.ch_code_line.nil?) ||
              (self.iban.nil? && self.ch_bank_account.present? && self.ch_code_line.nil?) ||
              (self.iban.nil? && self.ch_bank_account.nil? && self.ch_code_line.present?)) &&
            ((self.ch_postal_account.nil? && self.bic.present? && self.ch_bank_postal_account.nil? && self.ch_bank_name.nil?) || # V1
              (self.ch_postal_account.nil? && self.bic.present? && self.ch_bank_postal_account.present? && self.ch_bank_name.nil?) || # V2
              (self.ch_postal_account.nil? && self.bic.nil? && self.ch_bank_postal_account.present? && self.ch_bank_name.present?)) # V3
        when '3', nil
          valid_base &&
            self.ch_local_instrument.nil? &&
            self.iban.present? && self.ch_postal_account.nil? && self.bic.nil? && # IBAN only
            self.ch_bank_postal_account.nil? && self.ch_bank_name.nil? && self.ch_code_line.nil? # V3 only
        else
          raise 'not supported'
        end
      end
    end
  end
end

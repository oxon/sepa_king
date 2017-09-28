# encoding: utf-8
module SEPA
  class CreditTransferTransaction < Transaction
    attr_accessor :service_level

    validate { |t| t.validate_requested_date_after(Date.today) }

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
        self.service_level = nil # set by initializer, where the schema is not known, but should be empty for type 3 payments
        (self.remittance_information.nil? || self.remittance_reference.nil?) && self.service_level.nil? && %w(EUR CHF).include?(self.currency)
      end
    end
  end
end

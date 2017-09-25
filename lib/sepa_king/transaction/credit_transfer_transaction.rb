# encoding: utf-8
module SEPA
  class CreditTransferTransaction < Transaction
    attr_accessor :service_level

    validate { |t| t.validate_requested_date_after(Date.today) }

    def initialize(attributes = {})
      super
    end

    def schema_compatible?(schema_name)
      self.service_level ||= 'SEPA' unless schema_name == PAIN_001_001_03_CH_02
      case schema_name
      when PAIN_001_001_03
        self.service_level == 'SEPA'
      when PAIN_001_002_03
        self.bic.present? && self.service_level == 'SEPA' && self.currency == 'EUR'
      when PAIN_001_003_03
        self.currency == 'EUR' && self.service_level.in?(%w(SEPA URGP))
      when PAIN_001_001_03_CH_02
        self.service_level.nil? && self.currency.in?(%w(EUR CHF))
      end
    end
  end
end

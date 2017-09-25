# encoding: utf-8
module SEPA
  class CreditTransferTransaction < Transaction
    attr_accessor :service_level, :local_instrument, :payment_method, :creditor_account, :creditor_agent, :reference_number

    validate { |t| t.validate_requested_date_after(Date.today) }

    def initialize(attributes = {})
      super
    end

    def schema_compatible?(schema_name)
      if schema_name != PAIN_001_001_03_CH_02
        self.service_level ||= 'SEPA'
        return false if self.local_instrument.present? || self.payment_method.present? || self.creditor_agent.present? || self.reference_number.present?
        return false unless self.service_level.in?(%w(SEPA URGP))
      end
      case schema_name
        when PAIN_001_001_03
          self.service_level == 'SEPA'
        when PAIN_001_002_03
          self.bic.present? && self.service_level == 'SEPA' && self.currency == 'EUR'
        when PAIN_001_003_03
          self.currency == 'EUR'
        when PAIN_001_001_03_CH_02
          return false unless self.payment_method.in?(%w(TRF TRA))
          return false unless ch_payment_type_valid?
      end
    end

    def ch_payment_type_valid?
      if self.service_level == 'SEPA' # type 5
      else
        case self.local_instrument
          when 'CH01' # type 1
            self.service_level.nil? && self.currency.in?(%w(CHF EUR)) && self.creditor_agent.nil? && self.reference_number.present?
          when 'CH02' # type 2.1
            self.service_level.nil? && self.currency.in?(%w(CHF EUR)) && self.creditor_agent.nil? && self.reference_number.nil?
          when 'CH03' # type 2.2
            self.service_level.nil? && self.currency.in?(%w(CHF EUR)) && self.creditor_agent.present? && self.reference_number.nil?
          when nil # type 3 or 4 or 5 or 6, 7, 8
            if self.currency.in?(%w(CHF EUR)) # type 3, could be 5, 6, 7, 8
              if self.service_level == 'SEPA' # type 5
                # this is actually almost the international standard
                return false if self.local_instrument.present? || self.payment_method.present? || self.creditor_agent.present? || self.reference_number.present?
                self.currency == 'EUR'
              elsif self.service_level.nil? # type 3, could be 6, 7, 8
                raise 'types 3 and 6, 7, 8 not implemented'
              else
                false
              end
            else # type 4, could be 6, 8
              raise 'types 4 and 6, 8 not implemented'
            end
          else
            false
        end
      end
    end
  end
end

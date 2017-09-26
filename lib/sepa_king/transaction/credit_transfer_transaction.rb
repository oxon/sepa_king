# encoding: utf-8
module SEPA
  class CreditTransferTransaction < Transaction
    attr_accessor :service_level, :local_instrument, :payment_method, :creditor_account, :creditor_agent, :reference_number

    validate { |t| t.validate_requested_date_after(Date.today) }

    def initialize(attributes = {})
      super
    end

    def schema_compatible?(schema_name)
      # massive cyclomatic complexity, TODO: reduce
      if schema_name == PAIN_001_001_03_CH_02
        self.payment_method.in?(%w(TRF TRA)) && ch_payment_type_valid?
      else
        self.service_level ||= 'SEPA'
        !(self.local_instrument.present? || self.payment_method.present? || self.creditor_agent.present? || self.reference_number.present?) &&
          (self.service_level.in?(%w(SEPA URGP))) &&
          case schema_name
            when PAIN_001_001_03
              self.service_level == 'SEPA'
            when PAIN_001_002_03
              self.bic.present? && self.service_level == 'SEPA' && self.currency == 'EUR'
            when PAIN_001_003_03
              self.currency == 'EUR'
          end
      end
    end

    def ch_payment_type_valid?
      # massive cyclomatic complexity, TODO: reduce
      if self.service_level == 'SEPA' # type 5
        # this is actually almost the international standard
        !(self.local_instrument.present? || self.payment_method.present? || self.creditor_agent.present? || self.reference_number.present?) &&
          self.currency == 'EUR'
      else
        case self.local_instrument
          when 'CH01' # type 1
            self.service_level.nil? && self.currency.in?(%w(CHF EUR)) && self.creditor_agent.nil? && self.reference_number.present?
          when 'CH02' # type 2.1
            self.service_level.nil? && self.currency.in?(%w(CHF EUR)) && self.creditor_agent.nil? && self.reference_number.nil?
          when 'CH03' # type 2.2
            self.service_level.nil? && self.currency.in?(%w(CHF EUR)) && self.creditor_agent.present? && self.reference_number.nil? &&
              self.creditor_agent.is_a?(Hash) && [[:iid], [:account, :iid], [:account, :bank_name]].any? { |keys| self.creditor_agent.keys.sort == keys }
          when nil # type 3 or 4 or 5 or 6, 7, 8
            if self.currency.in?(%w(CHF EUR)) # type 3, could be 5, 6, 7, 8
              if self.service_level.nil? # type 3, could be 6, 7, 8
                raise 'types 3 and 6, 7, 8 not implemented'
              else # doesn't match a type
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

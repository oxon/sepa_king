# encoding: utf-8

module SEPA
  class CreditTransfer < Message
    include ::SEPA::Shared::PostalAddressBuilder

    self.account_class = DebtorAccount
    self.transaction_class = CreditTransferTransaction
    self.xml_main_tag = 'CstmrCdtTrfInitn'
    self.known_schemas = [ PAIN_001_003_03, PAIN_001_002_03, PAIN_001_001_03, PAIN_001_001_03_CH_02 ]

  private
    # Find groups of transactions which share the same values of some attributes
    def transaction_group(transaction)
      { requested_date: transaction.requested_date,
        batch_booking:  transaction.batch_booking,
        service_level:  transaction.service_level
      }
    end

    def build_payment_informations(builder, schema_name)
      # Build a PmtInf block for every group of transactions
      grouped_transactions.each do |group, transactions|
        # All transactions with the same requested_date are placed into the same PmtInf block
        builder.PmtInf do
          builder.PmtInfId(payment_information_identification(group))
          builder.PmtMtd('TRF')
          builder.BtchBookg(group[:batch_booking])
          unless schema_name == SEPA::PAIN_001_001_03_CH_02
            builder.NbOfTxs(transactions.length)
            builder.CtrlSum('%.2f' % amount_total(transactions))
            builder.PmtTpInf do
              builder.SvcLvl do
                builder.Cd(group[:service_level])
              end
            end
          end
          builder.ReqdExctnDt(group[:requested_date].iso8601)
          builder.Dbtr do
            builder.Nm(account.name)
          end
          builder.DbtrAcct do
            builder.Id do
              builder.IBAN(account.iban)
            end
          end
          builder.DbtrAgt do
            builder.FinInstnId do
              if schema_name == SEPA::PAIN_001_001_03_CH_02
                if account.bic.present?
                  builder.BIC(account.bic)
                end
                builder.ClrSysMmbId do
                  builder.ClrSysId do
                    builder.Cd('CHBCC')
                  end
                  unless account.bic.present?
                    builder.MmbId(account.clearing_number || '9000')
                  end
                end
              else
                if account.bic
                  builder.BIC(account.bic)
                else
                  builder.Othr do
                    builder.Id('NOTPROVIDED')
                  end
                end
              end
            end
          end
          builder.ChrgBr('SLEV') unless schema_name == SEPA::PAIN_001_001_03_CH_02

          transactions.each do |transaction|
            build_transaction(builder, transaction, schema_name)
          end
        end
      end
    end

    def build_transaction(builder, transaction, schema_name)
      builder.CdtTrfTxInf do
        builder.PmtId do
          if transaction.instruction.present?
            builder.InstrId(transaction.instruction)
          end
          builder.EndToEndId(transaction.reference)
        end
        builder.Amt do
          builder.InstdAmt('%.2f' % transaction.amount, Ccy: transaction.currency)
        end
        if (transaction.bic.present? || transaction.iban.start_with?('CH') || transaction.iban.start_with?('LI')) || transaction.creditor_bank_name.present? || transaction.creditor_bank_postal_address.present?
          builder.CdtrAgt do
            builder.FinInstnId do
              if transaction.bic.present?
                builder.BIC(transaction.bic)
              else # IBAN in CH/LI includes proprietary BIC / IID member ID
                builder.ClrSysMmbId do
                  builder.ClrSysId do
                    builder.Cd('CHBCC')
                  end
                  builder.MmbId(transaction.iban[4..8])
                end
              end
              builder.Nm(transaction.creditor_bank_name) if transaction.creditor_bank_name.present?
              builder.PstlAdr do
                build_postal_address(builder, transaction.creditor_bank_postal_address)
              end if transaction.creditor_bank_postal_address.present?
            end
          end
        end
        builder.Cdtr do
          builder.Nm(transaction.name)
          builder.PstlAdr do
            build_postal_address(builder, transaction.postal_address)
          end if transaction.postal_address.present?
        end
        builder.CdtrAcct do
          builder.Id do
            builder.IBAN(transaction.iban)
          end
        end
        if transaction.remittance_information.present?
          builder.RmtInf do
            builder.Ustrd(transaction.remittance_information)
          end
        elsif schema_name == SEPA::PAIN_001_001_03_CH_02 && transaction.remittance_reference.present?
          builder.RmtInf do
            builder.Strd do
              builder.CdtrRefInf do
                builder.Ref(transaction.remittance_reference)
              end
            end
          end
        end
      end
    end
  end
end

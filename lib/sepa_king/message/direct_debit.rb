# encoding: utf-8

module SEPA
  class DirectDebit < Message
    self.account_class = CreditorAccount
    self.transaction_class = DirectDebitTransaction
    self.xml_main_tag = 'CstmrDrctDbtInitn'
    self.known_schemas = [ PAIN_008_003_02, PAIN_008_002_02, PAIN_008_001_02, PAIN_008_001_02_CH_03 ]

    validate do |record|
      if record.transactions.map(&:local_instrument).uniq.size > 1
        errors.add(:base, 'CORE, COR1 AND B2B must not be mixed in one message!')
      end
    end

  private
    # Find groups of transactions which share the same values of some attributes
    def transaction_group(transaction)
      { requested_date:   transaction.requested_date,
        local_instrument: transaction.local_instrument,
        sequence_type:    transaction.sequence_type,
        batch_booking:    transaction.batch_booking,
        account:          transaction.creditor_account || account
      }
    end

    def build_payment_informations(builder, schema_name)
      # Build a PmtInf block for every group of transactions
      grouped_transactions.each do |group, transactions|
        builder.PmtInf do
          builder.PmtInfId(payment_information_identification(group))
          builder.PmtMtd('DD')
          unless schema_name == SEPA::PAIN_008_001_02_CH_03
            builder.BtchBookg(group[:batch_booking])
            builder.NbOfTxs(transactions.length)
            builder.CtrlSum('%.2f' % amount_total(transactions))
          end
          builder.PmtTpInf do
            builder.SvcLvl do
              if schema_name == SEPA::PAIN_008_001_02_CH_03
                builder.Prtry('CHDD')
              else
                builder.Cd('SEPA')
              end
            end
            builder.LclInstrm do
              if schema_name == SEPA::PAIN_008_001_02_CH_03
                builder.Prtry(group[:local_instrument])
              else
                builder.Cd(group[:local_instrument])
              end
            end
            builder.SeqTp(group[:sequence_type]) unless schema_name == SEPA::PAIN_008_001_02_CH_03
          end
          builder.ReqdColltnDt(group[:requested_date].iso8601)
          builder.Cdtr do
            builder.Nm(group[:account].name)
            builder.PstlAdr do
              build_postal_address(builder, group[:account].postal_address)
            end if group[:account].postal_address.present?
          end
          builder.CdtrAcct do
            builder.Id do
              builder.IBAN(group[:account].iban)
            end
          end
          builder.CdtrAgt do
            builder.FinInstnId do
              if schema_name == SEPA::PAIN_008_001_02_CH_03
                builder.ClrSysMmbId do
                  builder.MmbId('09000')
                end
              else
                if group[:account].bic
                  builder.BIC(group[:account].bic)
                else
                  builder.Othr do
                    builder.Id('NOTPROVIDED')
                  end
                end
              end
            end
          end
          builder.ChrgBr('SLEV') unless schema_name == SEPA::PAIN_008_001_02_CH_03
          builder.CdtrSchmeId do
            builder.Id do
              builder.PrvtId do
                builder.Othr do
                  builder.Id(group[:account].creditor_identifier)
                  builder.SchmeNm do
                    if schema_name == SEPA::PAIN_008_001_02_CH_03
                      builder.Prtry('CHDD')
                    else
                      builder.Prtry('SEPA')
                    end
                  end
                end
              end
            end
          end

          transactions.each do |transaction|
            build_transaction(builder, transaction, schema_name)
          end
        end
      end
    end

    def build_amendment_informations(builder, transaction)
      return unless transaction.original_debtor_account || transaction.same_mandate_new_debtor_agent
      builder.AmdmntInd(true)
      builder.AmdmntInfDtls do
        if transaction.original_debtor_account
          builder.OrgnlDbtrAcct do
            builder.Id do
              builder.IBAN(transaction.original_debtor_account)
            end
          end
        else
          builder.OrgnlDbtrAgt do
            builder.FinInstnId do
              builder.Othr do
                builder.Id('SMNDA')
              end
            end
          end
        end
      end
    end

    def build_transaction(builder, transaction, schema_name)
      builder.DrctDbtTxInf do
        builder.PmtId do
          if transaction.instruction.present?
            builder.InstrId(transaction.instruction)
          end
          builder.EndToEndId(transaction.reference)
        end
        builder.InstdAmt('%.2f' % transaction.amount, Ccy: transaction.currency)
        builder.DrctDbtTx do
          builder.MndtRltdInf do
            builder.MndtId(transaction.mandate_id)
            builder.DtOfSgntr(transaction.mandate_date_of_signature.iso8601)
            build_amendment_informations(builder, transaction)
          end
        end unless schema_name == SEPA::PAIN_008_001_02_CH_03
        builder.DbtrAgt do
          builder.FinInstnId do
            if schema_name == SEPA::PAIN_008_001_02_CH_03
              builder.ClrSysMmbId do
                builder.MmbId('09000')
              end
            else
              if transaction.bic
                builder.BIC(transaction.bic)
              else
                builder.Othr do
                  builder.Id('NOTPROVIDED')
                end
              end
            end
          end
        end
        builder.Dbtr do
          builder.Nm(transaction.name)
          builder.PstlAdr do
            build_postal_address(builder, transaction.postal_address)
          end if transaction.postal_address.present?
        end
        builder.DbtrAcct do
          builder.Id do
            builder.IBAN(transaction.iban)
          end
        end
        if transaction.remittance_information
          builder.RmtInf do
            builder.Ustrd(transaction.remittance_information)
          end
        end
      end
    end

    def build_postal_address(builder, postal_address)
      builder.Ctry(postal_address.country) if postal_address.country.present?
      builder.StrtNm(postal_address.street_name) if postal_address.street_name.present?
      builder.PstCd(postal_address.postal_code) if postal_address.postal_code.present?
      builder.TwnNm(postal_address.town_name) if postal_address.town_name.present?
      builder.AdrLine(postal_address.address_line_1) if postal_address.address_line_1.present?
      builder.AdrLine(postal_address.address_line_2) if postal_address.address_line_2.present?
    end
  end
end

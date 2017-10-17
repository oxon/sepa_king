module SEPA
  module Shared
    module PostalAddressBuilder

      def build_postal_address(builder, postal_address)
        builder.StrtNm(postal_address.street_name) if postal_address.street_name.present?
        builder.BldgNb(postal_address.building_number) if postal_address.building_number.present?
        builder.PstCd(postal_address.postal_code) if postal_address.postal_code.present?
        builder.TwnNm(postal_address.town_name) if postal_address.town_name.present?
        builder.AdrLine(postal_address.address_line_1) if postal_address.address_line_1.present?
        builder.AdrLine(postal_address.address_line_2) if postal_address.address_line_2.present?
        builder.Ctry(postal_address.country) if postal_address.country.present?
      end

    end
  end
end

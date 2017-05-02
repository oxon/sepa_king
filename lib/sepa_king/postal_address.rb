# encoding: utf-8
module SEPA
  class PostalAddress
    include ActiveModel::Validations
    extend Converter

    attr_accessor :country, :street_name, :postal_code, :town_name, :address_line_1, :address_line_2
    convert :country, :street_name, :postal_code, :town_name, :address_line_1, :address_line_2, to: :text

    def initialize(attributes = {})
      attributes.each do |name, value|
        public_send("#{name}=", value)
      end
    end
  end
end
# coding: UTF-8

class Spree::RussianPost::Calculator < Spree::ShippingCalculator
  include RussianPostCalc

  # Post code of the sender.
  preference :sender_post_code,             :string,    :default => '190000'

  # Calculated price will we multipied to 100% + cache_on_delivery_percentage%
  preference :cache_on_delivery_percentage, :decimal, :default => 0

  # If this value is set, given payment method will be used and payment method selection
  # will be disabled. Usually used for cache on delivery.
  preference :autoselect_payment_method_id, :integer

  # Use declared value for calculation.
  preference :use_declared_value,           :boolean, :default => false

  def self.description
    I18n.t(:russian_post_description)
  end

  def compute(object = nil, options = {})
    # Get order from the object.
    order  = object.is_a?(::Spree::Order) ? object : object.order
    weight = compute_weight(order)

    declared_value = preferred_use_declared_value ? order.line_items.map(&:amount).sum : 0

    sender_post_code     = preferred_sender_post_code
    ship_address_zipcode = options[:ship_address_zipcode] || order.ship_address.zipcode

    # Calculate delivery price itself.
    calculate_price sender_post_code, ship_address_zipcode, weight, declared_value
  end

  # Computes weight for the given order.
  #
  # @param [Spree::Order, Spree::Shipment] object Object to calculate weight of. Can be Order or Shipment
  #
  # @return [Float] calculated weight [kilogramms].
  #
  # TODO (VZ): Move it to the order class. Perhabs add caching to this fiesld's value.
  # TODO (VZ): Add weight caching to the line item.
  def compute_weight object
    object.line_items.map { |li| (li.variant.weight || 0)  * li.quantity }.sum
  end

  def calculate_price sender_post_code, destination_post_code, weight, declared_value = 0
    weight = if weight < 0.75
               0
             elsif weight > 20
               then raise "Максимальный вес для отправления: 20 кг."
             else
               ((weight - 0.25) / 0.5).floor * 0.5 + 0.25
             end

    self.class.calculate_delivery_price sender_post_code, destination_post_code, weight, declared_value
  end
end

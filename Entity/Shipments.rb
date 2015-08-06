module Entity

  class Shipments < Sinatra::Base
    def self.get_format_shipment_data(shipment_response,payload,headers,config)
      shipment_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :shipments => format_wombat_shipment_data(shipment_response,headers,config)
      }
      shipment_json
    end

    def self.format_wombat_shipment_data(shipment_responses,headers,config)
     datas =[]
     shipment_responses.each do |shipment_response|
        data = {
            :id => shipment_response['id'],
            :order_id => shipment_response['order_id'],
            :email => shipment_response['billing_address']['email'],
            :shipping_method => shipment_response['shipping_method'],
            :updated_at => shipment_response['date_created'],
            :shipped_at => shipment_response['date_created'],
            :status => 'ready',
            # :order_status => order status,
            :stock_location => 'default',
            :shipping_address =>{
              :firstname => shipment_response['shipping_address']['first_name'],
              :lastname => shipment_response['shipping_address']['last_name'],
              :address1 => shipment_response['shipping_address']['street_1'],
              :address2 => shipment_response['shipping_address']['street_2'],
              :city => shipment_response['shipping_address']['city'],
              :state => shipment_response['shipping_address']['state'],
              :country => shipment_response['shipping_address']['country_iso2'],
              :phone => shipment_response['shipping_address']['phone',]
             },
            :billing_address =>{
                :firstname => shipment_response['billing_address']['first_name'],
                :lastname => shipment_response['billing_address']['last_name'],
                :address1 => shipment_response['billing_address']['street_1'],
                :address2 => shipment_response['billing_address']['street_2'],
                :city => shipment_response['billing_address']['city'],
                :state => shipment_response['billing_address']['state'],
                :country => shipment_response['billing_address']['country_iso2'],
                :phone => shipment_response['billing_address']['phone',]
            },
            :items => get_Order_Products(shipment_response['order_id'],headers,config),
        }
        datas << data
      end
      datas
    end

    def self.get_Order_Products(order_id,headers,config)
      products = Service.request_bigapp :get, "/orders/#{order_id}/products",headers,config
      items =[]
      unless products.empty?
        products.each do |product|
          item = {
              :name => product['name'],
              :product_id => product['product_id'],
              :quantity => product['quantity'],
              :price => convert_price(product['total_inc_tax']),

          }
          items << item
        end
        items
      end
    end
    def self.convert_price(price)
      @price = price.to_f
      rounded_price = @price.round(2)
      rounded_price
    end
  end
end
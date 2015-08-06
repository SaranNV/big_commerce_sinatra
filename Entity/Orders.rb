module Entity

  class Orders < Sinatra::Base
    def self.get_format_order_data(order_data,payload,headers,config1)
      order_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :orders => format_wombat_object(order_data,headers,config1)
      }
      formatted_order_json =  JSON.pretty_generate(order_json)
      formatted_order_json
    end

    def self.format_wombat_object(responses,headers,config1)
      datas = []
      order_products = []
      responses.each do |response|
        shipping_address = Service.request_bigapp :get, "/orders/#{response['id']}/shipping_addresses",  headers, config1
        products = Service.request_bigapp :get, "/orders/#{response['id']}/products",  headers, config1
        products.each do |product|
         product_details = {
            :product_id => product['product_id'],
            :name => product['name'],
            :quantity => product['quantity'],
            :price => convert_price(product['total_inc_tax']),
            :bigcommerce_id => product['id'],
            :bigcommerce_product_id => product['product_id']
          }
          order_products << product_details
        end
        data ={
            :id => response['id'],
            :status => response['status'],
            :email => response['billing_address']['email'],
            :currency => response['currency_code'],
            :placed_on => response['date_created'],
            :totals => {
                :item => response['subtotal_ex_tax'].to_f,
                :discount => response['discount_amount'].to_f + response['coupon_discount'].to_f,
                :tax => response['total_tax'].to_f,
                :shipping => response['shipping_cost_ex_tax'].to_f,
                :payment =>response['total_inc_tax'].to_f,
                :order => response['total_inc_tax'].to_f,
            },
            :line_items => order_products,
            :bigcommerce_id => response['id'],
            :shipping_address => {
                :firstname => shipping_address.first['first_name'],
                :lastname => shipping_address.first['last_name'],
                :address1 => shipping_address.first['street_1'],
                :address2 => shipping_address.first['street_2'],
                :zipcode => shipping_address.first['zip'],
                :city => shipping_address.first['city'],
                :state => shipping_address.first['state'],
                :country => shipping_address.first['country_iso2'],
                :phone => shipping_address.first['phone']
            },
            :order_message => response['customer_message'],
            :billing_address => {
                :firstname => response['billing_address']['first_name'],
                :lastname => response['billing_address']['last_name'],
                :address1 => response['billing_address']['street_1'],
                :address2 => response['billing_address']['street_2'],
                :zipcode => response['billing_address']['zip'],
                :city => response['billing_address']['city'],
                :state => response['billing_address']['state'],
                :country => response['billing_address']['country_iso2'],
                :phone => response['billing_address']['phone']
            },
            :shipping_method => shipping_address.first['shipping_method']
        }
        datas << data
        order_products = []
      end
      datas
    end

    def self.convert_price(price)
      @price = price.to_f
      rounded_price = @price.round(2)
      rounded_price
    end

  end
end

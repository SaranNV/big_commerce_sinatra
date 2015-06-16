module Entity

  class Orders < Sinatra::Base
    def self.get_format_order_data(order_data,payload)
      order_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :orders => format_wombat_object(order_data)
      }
      formatted_order_json =  JSON.pretty_generate(order_json)
      formatted_order_json
    end
  end
end

def format_wombat_object(order_datas)
  datas = []
  order_datas.each do |order_data|
    data ={
      :id => order_data['id'],
      :status => order_data['status'],
      :email => order_data['billing_address']['email'],
      :currency => order_data['currency_code'],
      :placed_on => order_data['date_created'],
      :totals => {
        :item => order_data['subtotal_ex_tax'].to_f,
        :discount => order_data['discount_amount'].to_f + order_data['coupon_discount'].to_f,
        :tax => order_data['total_tax'].to_f,
        :shipping => order_data['shipping_cost_ex_tax'].to_f,
        :payment =>order_data['total_inc_tax'].to_f,
        :order => order_data['total_inc_tax'].to_f,
      },
      :order_message => order_data['customer_message'],
      :billing_address => {
        :firstname => order_data['billing_address']['first_name'],
        :lastname => order_data['billing_address']['last_name'],
        :address1 => order_data['billing_address']['street_1'],
        :address2 => order_data['billing_address']['street_2'],
        :zipcode => order_data['billing_address']['zip'],
        :city => order_data['billing_address']['city'],
        :state => order_data['billing_address']['state'],
        :country => order_data['billing_address']['country_iso2'],
        :phone => order_data['billing_address']['phone']

      }

    }
   datas << data
    end
 datas
end
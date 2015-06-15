module Entity

  class Orders < Sinatra::Base
    def self.get_format_order_data(response,payload)
      my_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :orders => format_wombat_object(response)
      }
      pretty_json =  JSON.pretty_generate(my_json)
      pretty_json
    end

    def format_wombat_object(responses)
      datas = []
      responses.each do |response|
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

            }

        }
        datas << data
      end
      datas
    end
  end
end
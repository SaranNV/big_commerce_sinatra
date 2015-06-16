module Entity

  class Customers < Sinatra::Base
    def self.get_format_customer_data(customer_data,payload)
      customer_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :customers => customer_data
      }
      formatted_json =  JSON.pretty_generate(customer_json)
      formatted_json
    end

    def self.post_format_data(customer_options)
      customer = {
          :first_name => customer_options['firstname'],
          :last_name =>customer_options['lastname'],
          :email => customer_options['email'],
      }
      customer
    end
  end
end
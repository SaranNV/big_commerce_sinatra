module Entity

  class Customers < Sinatra::Base
    def self.get_format_customer_data(response,payload)
      my_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :customers => response
      }
      pretty_json =  JSON.pretty_generate(my_json)
      pretty_json
    end

    def self.post_format_data(customer_options)
      customer = {
          :first_name => customer_options['first_name'],
          :last_name =>customer_options['last_name'],
          :email => customer_options['email'],
      }
      customer
    end
  end
end
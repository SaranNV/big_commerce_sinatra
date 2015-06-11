module Entity

  class Orders < Sinatra::Base
    def self.get_format_order_data(response,payload)
      my_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :orders => response
      }
      pretty_json =  JSON.pretty_generate(my_json)
      pretty_json
    end
  end
end
module Entity
  class Products < Sinatra::Base
    def self.get_format_data(response,payload)
      my_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :products => response
      }
      pretty_json =  JSON.pretty_generate(my_json)
      pretty_json
    end
  end
end




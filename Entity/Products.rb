module Entity
  class Products < Sinatra::Base
    def self.get_format_product_data(product_data,payload)
      products_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :products => product_data
      }
      pretty_json =  JSON.pretty_generate(products_json)
      pretty_json
    end
  end
end




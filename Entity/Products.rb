module Entity
  class Products < Sinatra::Base
    def self.get_format_product_data(product_data,payload)
      products_json = {
          :request_id => payload['request_id'],
          :parameters => payload['parameters'],
          :products => format_product_data_to_wombat(product_data)
      }
      pretty_json =  JSON.pretty_generate(products_json)
      pretty_json
    end

    def self.format_product_data_to_wombat(product_datas)
      datas = []
      product_datas.each do |product|
        data ={
          :id => product['id'],
          :name => product['name'],
          :type => product['type'],
          :sku => product['sku'],
          :description => product['description'],
          :price => convert_price(product['price']),
          :cost_price => product['cost_price'],
          :retail_price => product['retails_price'],
          :sale_price => product['sale_price'],
          :calculated_price => product['calculated_price'],
          :sort_order => product['sort_order'],
          :weight => product['weight'],
          :inventory_tracking => product['inventory_tracking'],
          :date_created => product['date_created'],
          :meta_keywords => product['meta_keywords'],
          :meta_description => product['meta_description'],
          :categories => product['categories'].first
        }
        datas << data
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




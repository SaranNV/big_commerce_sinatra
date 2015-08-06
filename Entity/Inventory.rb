module Entity

  class Inventory < Sinatra::Base

    def self.push(payload,headers,config)
      wombat_object = payload['inventory']
      bigcommerce_data = {:inventory_level => wombat_object['quantity']}
      get_product = Service.request_bigapp :get,"/products",{:sku => wombat_object['sku']}, headers, config
      find_skus_product = Service.request_bigapp :get,"/products/skus",{:sku => wombat_object['sku']}, headers, config
      if !get_product.empty?
          product_id = get_product.first['id']
          get_inventory_track =  Service.request_bigapp :get,"/products/#{product_id}","", headers, config
          if !get_inventory_track['inventory_tracking'] == 'none'
            response = Service.request_bigapp :put,"/products/#{product_id}",bigcommerce_data, headers, config
            response_message = {:message => "The Inventory #{wombat_object['id']} for product: #{wombat_object['product_id']} was updated in BigCommerce"}
            return JSON.pretty_generate(response_message)
          else
            response =  {:error => "This product does not have inventory tracking enabled."}
            return JSON.pretty_generate(response)
          end
      elsif !find_skus_product.empty?
          product_id = find_skus_product.first['product_id']
          sku_id = find_skus_product.first['id']
          get_inventory_track =  Service.request_bigapp :get,"/products/#{product_id}","", headers, config
          if !get_inventory_track['inventory_tracking'] == 'none'
            response = Service.request_bigapp :put,"/products/#{product_id}/skus/#{sku_id}",bigcommerce_data, headers, config
            response_message = {:message => "The Inventory #{wombat_object['id']} for product: #{wombat_object['product_id']} was updated in BigCommerce"}
            return JSON.pretty_generate(response_message)
          else
            response =  {:error => "This product does not have inventory tracking enabled."}
            return JSON.pretty_generate(response)
          end
      else
        response = {:message => "No product could be found for sku"}
        return JSON.pretty_generate(response)
      end

    end

  end
end
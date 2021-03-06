require 'sinatra'
require 'httparty'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'
require 'base64'
require 'bigcommerce'
require 'rest-client'
require_relative 'Entity/Products'
require_relative 'Entity/Orders'
require_relative 'Entity/Customers'
require_relative 'Entity/Shipments'
require_relative 'Entity/Inventory'
require 'securerandom'
class BigApp < Sinatra::Base
  attr_reader :payload

  before  do
    unless request.env['PATH_INFO'] == '/'
      request.body.rewind
        @payload = JSON.parse(request.body.read).with_indifferent_access

        @config1 = Bigcommerce::Api.new({
                                        :username => @payload['parameters']['api_username'],
                                        :store_url => @payload['parameters']['api_path'],
                                        :api_key => @payload['parameters']['api_token']
                                    })
        @headers = {"Content-Type" => "application/json", 'Accept' => 'application/json'}
    end
  end

  get '/' do
    erb :index
  end

  post '/add_product' do
    content_type :json
    add_product_data = @payload['product']
    @category = Service.get_or_create_category(add_product_data['categories'].first,@headers, @config1)
    add_product_data['categories'] = [
             @category
    ]
     product_data = Service.request_bigapp :post, "/products", add_product_data, @headers, @config1
     if product_data['price'].present?
      @price =  product_data['price'].to_f
      product_data['price'] = @price.round(2)
     end
     return JSON.pretty_generate(product_data)
  end

  post '/get_products' do
    content_type :json
    min_date_modified = @payload['parameters']['min_date_modified']
    product_options = min_date_modified
    get_products_data = Service.request_bigapp :get, "/products", {:min_date_modified => product_options }, @headers, @config1
    Entity::Products.get_format_product_data(get_products_data,@payload)
  end


  post '/update_product' do
    update_product_data = @payload['product']
    product_detail = update_product_data.except(:product_id)
    product_data = Service.request_bigapp :put, "/products/#{update_product_data['product_id']}", product_detail, @headers, @config
    return JSON.pretty_generate(product_data)
  end

  post '/add_customer' do
    content_type :json
    add_customer_data = @payload['customer']
    customer_data = Entity::Customers.post_format_data(add_customer_data)
    customer_details = Service.request_bigapp :post, "/customers", customer_data, @headers, @config1
    return JSON.pretty_generate(customer_details)
  end

  post '/get_customers' do
    content_type :json
    get_customer_data =  @payload['parameters']['min_date_created']
    customer_options = get_customer_data
    customer_details = Service.request_bigapp :get, "/customers", {:min_date_created => customer_options}, @headers, @config1
    Entity::Customers.get_format_customer_data(customer_details,@payload)

  end


  post '/add_order' do
    content_type :json
    add_order_data = @payload['order']
      order_data = Service.request_bigapp :post, "/orders", add_order_data, @headers, @config1
      return JSON.pretty_generate(order_data)
  end



  post '/get_orders' do
    content_type :json
    min_date_modified =  @payload['parameters']['min_date_modified']
    order_options = min_date_modified
    get_order_datas = Service.request_bigapp :get, "/orders",  {:min_date_modified => order_options }, @headers, @config1

    Entity::Orders.get_format_order_data(get_order_datas,@payload,@headers,@config1)
  end

  post '/update_order' do
    update_order_data = @payload['order']
    order_detail = update_order_data.except(:order_id)
    response = Service.request_bigapp :put, "/orders/#{update_order_data['order_id']}", order_detail, @headers, @config1
    return JSON.pretty_generate(response)
  end

  post '/get_shipments' do
    content_type :json
    shipment_datas = []
    # this line was active before demo for zeeberry deploy into master still-eyrine (29-7-15)
    # list_orders = Service.list_all_order(@config1,@headers)  previous code

    # content_type :json
    min_date_modified =  @payload['parameters']['min_date_modified']
    order_options = min_date_modified
    list_orders = Service.request_bigapp :get, "/orders",  {:min_date_modified => order_options }, @headers, @config1

    # Entity::Orders.get_format_order_data(get_order_datas,@payload,@headers,@config1)



    get_shipments_data = @payload['parameters']['min_date_modified']
    list_orders.each do |order|
      data = Service.request_bigapp :get, "/orders/#{order['id']}/shipments", get_shipments_data, @headers, @config1
      shipment_datas += data
    end
    shipment_response = shipment_datas.reject &:empty?
    shipment_json = Entity::Shipments.get_format_shipment_data(shipment_response,@payload,@headers,@config1)
    return JSON.pretty_generate(shipment_json)
  end

  post '/add_shipment' do
    content_type :json
    add_shipment_data = @payload['shipment']
    order_id = @payload['shipment']['id'] || @payload['shipment']['order_id']
    get_order_response = Service.request_bigapp :get, "/orders/#{order_id}", "", @config1
    if get_order_response.class == Hash
        @order_address = Service.request_bigapp :get, "/orders/#{order_id}/shipping_addresses",  @headers, @config1
        add_shipment_data['order_address_id'] = @order_address.first['id']
        @order_product = Service.request_bigapp :get, "/orders/#{order_id}/products",  @headers, @config1
        items = []
        @order_product.each do |product_data|
          item = {
              :order_product_id => product_data['id'],
              :quantity => product_data['quantity']
          }
          items << item
        end
        add_shipment_data['items'] = items
        if @payload['shipment']['tracking'].nil?
          add_shipment_data['tracking_number'] = SecureRandom.hex(7).upcase
        else
          add_shipment_data['tracking_number'] = @payload['shipment']['tracking']
        end
        shipment_format_data = {
            :tracking_number => add_shipment_data['tracking_number'],
            :order_address_id =>  add_shipment_data['order_address_id'],
            :items => items
        }
        # add_shipment_data = add_shipment_data.except(:id,:status,:tracking)
        response = Service.request_bigapp :get, "/orders/#{order_id}/shipments", shipment_format_data, @headers, @config1

        if response.empty?
          shipment_response = Service.request_bigapp :post, "/orders/#{order_id}/shipments", shipment_format_data, @headers, @config1
          update_order_status = {
              :status_id => "2"
          }
          @update_order_status = Service.request_bigapp :put, "/orders/#{order_id}",update_order_status,@headers,@config1
          return JSON.pretty_generate(shipment_response)
        else
          shipment_id = response.first['id']
          add_shipment_data = add_shipment_data.except(:items)
          shipment_response = Service.request_bigapp :put, "/orders/#{order_id}/shipments/#{shipment_id}", shipment_format_data, @headers, @config1
          return JSON.pretty_generate(shipment_response)
        end
    else
          return []
    end
  end

  post '/get_shipment' do
       content_type :json
      limit = @payload['parameters']['limit']
      order_id = @payload['shipment']['order_id']
      shipment_id = @payload['shipment']['shipment_id']
      response = Service.request_bigapp :get, "/orders/#{order_id}/shipments/#{shipment_id}",{:limit => '100'}, headers, @config1
      Entity::Shipments.get_format_shipment_data(response,@payload, headers, @config1)
  end

  post '/set_inventory' do
    content_type :json
    Entity::Inventory.push(@payload,headers,@config1)
    # result_set_inventory = Entity::Inventory.push(@payload,headers,@config1)
    # inventory_json = {
    #     :request_id => @payload['request_id'],
    #     :parameters => @payload['parameters'],
    #     :inventory => result_set_inventory
    # }
  end
end


class Service
  attr_reader :payload

  def initialize(payload = {})
    @payload = payload
  end

  def self.request_bigapp(method, path, options, headers={}, config)
    @config = config.connection.configuration
    resource_options = {
        :user => @config[:username],
        :password => @config[:api_key],
        :headers => headers
    }

    rest_client = RestClient::Resource.new "#{@config[:store_url]}/api/v2#{path}.json", resource_options

    response = case method
                 when :get then
                    begin
                      rest_client.get :params => options, :content_type => :json, :accept => :json
                    rescue => e
                      e.response
                    end
                 when :post then
                   begin
                     rest_client.post(options.to_json, :content_type => :json, :accept => :json)
                   rescue => e
                     e.response
                   end
                 when :put then
                   rest_client.put(options.to_json, :content_type => :json, :accept => :json)
                 when :delete then
                   rest_client.delete
                 when :head then
                   rest_client.head
                 when :options then
                   rest_client.options
                 else
                   raise 'Unsupported method!'
               end


    if (200..201) === response.code
      JSON.parse response
    elsif response.code == 404
      exception = JSON.parse response
      exception.each do |response_error|
        return response_error['message']
      end
    elsif response.code == 204
      return []
    elsif response.code == 409
      exception = JSON.parse response
      exception.each do |response_error|
        if response_error['details']['conflict_reason']
          return {:error => response_error['details']['conflict_reason']}
        else
          return {:error => response_error['message']} #Out of stock product message
        end
      end
    elsif response.code == 400
      exception = JSON.parse response
      exception.each do |response_error|
        return {:error => response_error['message']}
      end
    end
  end

  def self.list_all_order(config,headers)
    @config = config.connection.configuration
    resource_options = {
        :user => @config[:username],
        :password => @config[:api_key],
        :headers => headers
    }

    rest_client = RestClient::Resource.new "#{@config[:store_url]}/api/v2/orders.json", resource_options
    response = rest_client.get  :accept => :json, :content_type => :json


    if (200..201) === response.code
      JSON.parse response

    elsif response.code == 204
      return []
    end
  end

  def self.get_or_create_category(category,headers,config)
    category_name = category
    response = Service.request_bigapp :get, "/categories",{:name=>category_name},headers,config
    unless response.present?
      #if the response is empty  category was not exist on store,so we are creating new one"
      response =Service.request_bigapp :post, "/categories",{:name=>category_name},headers,config
      category_id = response['id']
    else
      category_id = response.first['id']
    end
    category_id
  end

  class ResponseError < StandardError;
  end

end

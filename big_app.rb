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

class BigApp < Sinatra::Base
  attr_reader :payload

  before  do
    unless request.env['PATH_INFO'] == '/'
      request.body.rewind
      request_val = request.body.read
      unless request_val == ""
        @payload = JSON.parse(request_val).with_indifferent_access

        @config1 = Bigcommerce::Api.new({
                                        :username => @payload['parameters']['api_username'],
                                        :store_url => @payload['parameters']['api_path'],
                                        :api_key => @payload['parameters']['api_token']
                                    })
        @headers = {"Content-Type" => "application/json", 'Accept' => 'application/json'}
      end
    end
  end

  get '/' do
    erb :login
  end

  get '/demo' do
    erb :index
  end

  post '/add_product' do
    content_type :json
    add_product_data = @payload['product']
    add_product_data.each do |product_options|
         response = Service.request_bigapp :post, "/products", product_options, @headers, @config1
         puts response
         return JSON.pretty_generate(response).to_json
    end
  end


  post '/get_products' do
    content_type :json
    min_date_modified = @payload['parameters']['min_date_modified']
    product_options = min_date_modified
    response = Service.request_bigapp :get, "/products", {:min_date_modified => product_options }, @headers, @config1
    Entity::Products.get_format_product_data(response,@payload)
  end


  post '/update_product' do
    update_product_data = @payload['product']
    update_product_data.each do |product_options|
      product_detail = product_options.except(:product_id)
      response = Service.request_bigapp :put, "/products/#{product_options['product_id']}", product_detail, @headers, @config1
      return JSON.pretty_generate(response)
    end
  end

  post '/add_customer' do
    content_type :json
    add_customer_data = @payload['customer']
      customer_data = Entity::Customers.post_format_data(add_customer_data)
      response = Service.request_bigapp :post, "/customers", customer_data, @headers, @config1
      return JSON.pretty_generate(response)
      # response.to_json
  end

  post '/get_customers' do
    content_type :json
    get_customer_data =  @payload['parameters']['min_date_created']
    customer_options = get_customer_data
      response = Service.request_bigapp :get, "/customers", {:min_date_created => customer_options}, @headers, @config1
      Entity::Customers.get_format_customer_data(response,@payload)
  end


  post '/add_order' do
    add_order_data = @payload['order']
    add_order_data.each do |order_options|
      response = Service.request_bigapp :post, "/orders", order_options, @headers, @config1
      puts response
      return JSON.pretty_generate(response)
    end
  end


  post '/get_orders' do
    content_type :json
    min_date_modified =  @payload['parameters']['min_date_modified']
    order_options = min_date_modified
    response = Service.request_bigapp :get, "/orders",  {:min_date_modified => order_options }, @headers, @config1
    Entity::Orders.get_format_order_data(response,@payload)
  end


  post '/get_shipments' do
    order_ids = []
    shipments = []
    shipped_order_ids = []
    partially_shipped_order_ids = []
    @payload['status_id'] = '2'; #shipped
    min_date_modified =  @payload['parameters']['min_date_modified']
    order_options = min_date_modified
    shipped_orders = Service.request_bigapp :get, "/orders",  {:min_date_modified => order_options,:status_id =>  @payload['status_id'] }, @headers, @config1
    unless shipped_orders.empty?
      shipped_orders.each do |order|
        shipped_order_ids << order['id']
      end
      shipped_order_ids
    end

    @payload['status_id'] = '3'; #partially shipped
    min_date_modified =  @payload['parameters']['min_date_modified']
    order_options = min_date_modified
    partially_shipped_orders = Service.request_bigapp :get, "/orders",  {:min_date_modified => order_options,:status_id =>  @payload['status_id'] }, @headers, @config1
    unless partially_shipped_orders.empty?
      partially_shipped_orders.each do |order|
        partially_shipped_order_ids << order['id']
       end
      partially_shipped_order_ids
    end
    #   merge both shipped order ids and partially shipped_order_ids
    order_ids = shipped_order_ids + partially_shipped_order_ids
    min_date_modified =  @payload['parameters']['min_date_modified']
    order_options = min_date_modified
    content_type :json
    puts "#{ payload['request_id']}"
    unless order_ids.empty?
      order_ids.each do |order_id|
        response = Service.request_bigapp :get, "/orders/#{order_id}/shipments",  {:min_date_modified => order_options }, @headers, @config1
        my_json = {
            :request_id => @payload['request_id'],
            :parameters => @payload['parameters'],
            :shipments => response
        }
        shipments << my_json

      end

    end
    pretty_json =  JSON.pretty_generate(shipments)
    pretty_json
  end


  post '/get_shipment' do
       content_type :json
      limit = @payload['parameters']['limit']
      order_id = @payload['shipment']['order_id']
      shipment_id = @payload['shipment']['shipment_id']
      response = Service.request_bigapp :get, "/orders/#{order_id}/shipments/#{shipment_id}",{:limit => '100'}, headers, @config1
      Entity::Shipments.get_format_shipment_data(response,@payload)
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
                   rest_client.get :params => options, :content_type => :json, :accept => :json
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
    elsif response.code == 204
      return []
    elsif response.code == 409
      exception = JSON.parse response
      exception.each do |response_error|
        return {:error => response_error['details']['conflict_reason']}
      end
    elsif response.code == 400
      exception = JSON.parse response
      exception.each do |response_error|
        return {:error => response_error['message']}
      end
    end
  end
  class ResponseError < StandardError;
  end

end

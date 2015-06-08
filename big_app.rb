require 'sinatra'
require 'httparty'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'
require 'base64'
require 'bigcommerce'
require 'rest-client'

class BigApp < Sinatra::Base
  attr_reader :payload

  before  do
    unless request.env['PATH_INFO'] == '/'
      request.body.rewind
      @payload = JSON.parse(request.body.read).with_indifferent_access
      puts "#{@payload}"
      # connections = @config
      @config1 = Bigcommerce::Api.new({
                                      :store_url => @payload['parameters']['api_path'],
                                      :username => @payload['parameters']['api_username'],
                                      :api_key => @payload['parameters']['api_token']
                                  })
      @headers = {"Content-Type" => "application/json", 'Accept' => 'application/json'}
    end
  end


  post '/add_product' do
    add_product_data = @payload['product']
    add_product_data.each do |product_options|
         response = Service.request_bigapp :post, "/products", product_options, @headers, @config1
         puts response
         return JSON.pretty_generate(response)
    end
  end

  post '/get_products_demo' do
    get_product_data = @payload['products']

     get_product_data.each do |product_options|
       last_modified_date = product_options['min_date_created']
      response = Service.request_bigapp :get, "/products", product_options, @headers, @config1
      return JSON.pretty_generate(response.last['date_modified'])
     end
  end

  post '/get_products' do
    puts "parameter changed"
    puts "#{@payload['parameters']['min_date_modified']}"
    # get_product_data.each do |product_options|

    min_date_modified = @payload['parameters']['min_date_modified']
    product_options = min_date_modified
      response = Service.request_bigapp :get, "/products", {:min_date_modified => product_options }, @headers, @config1
        # final_response = response.to_json
     #  final_response = response.map { |o| Hash[o.each_pair.to_a] }.to_json
     #  puts "#{final_response}"
     #  final_response = final_response.to_json
       puts "response"
      puts "#{response}"

    # end
  end


  post '/update_product' do
    update_product_data = @payload['product']
    update_product_data.each do |product_options|
      product_detail = product_options.except(:product_id)
      response = Service.request_bigapp :put, "/products/#{product_options['product_id']}", product_detail, @headers, @config
      return JSON.pretty_generate(response)
    end
  end

  post '/add_customer' do
    add_customer_data = @payload['customer']
    add_customer_data.each do |customer_options|
      response = Service.request_bigapp :post, "/customers", customer_options, @headers, @config
      return JSON.pretty_generate(response)
    end
  end

  post '/get_customers' do
    get_customer_data = @payload['customers']
    get_customer_data.each do |customer_options|
      response = Service.request_bigapp :get, "/customers", customer_options, @headers, @config
      return JSON.pretty_generate(response)
    end
  end


  post '/add_order' do
    add_order_data = @payload['order']
    add_order_data.each do |order_options|
      response = Service.request_bigapp :post, "/orders", order_options, @headers, @config
      puts response
      return JSON.pretty_generate(response)
    end
  end


  post '/get_orders' do
    get_order_data = @payload['orders']
    get_order_data.each do |order_options|
      response = Service.request_bigapp :get, "/orders", order_options, @headers, @config
      return JSON.pretty_generate(response)
    end
  end


  post '/get_shipments' do
    resp_val = []
    list_orders = Service.list_all_order(@config,@headers)
    get_shipments_data = @payload['shipments']
   list_orders.each do |order|
      response = Service.request_bigapp :get, "/orders/#{order['id']}/shipments", get_shipments_data, @headers, @config
      resp_val << response
    end
    reject_empty_array = res_val.reject &:empty?
    return JSON.pretty_generate(reject_empty_array)
  end


  post '/get_shipment' do
    get_shipment_data = @payload['shipment']
    get_shipment_data.each do |shipment_options|
      response = Service.request_bigapp :get, "/orders/#{shipment_options['order_id']}/shipments", shipment_options, headers, api
      return JSON.pretty_generate(response)
    end
  end

  get '/' do
    erb :index
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
                   rest_client.get :params => options, :accept => :json, :content_type => :json
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
        return response_error['details']['conflict_reason']
      end
    elsif response.code == 400
      exception = JSON.parse response
      exception.each do |response_error|
        return response_error['message']
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

  class ResponseError < StandardError;
  end

end

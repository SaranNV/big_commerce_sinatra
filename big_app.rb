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
       @payload = JSON.parse(request.body.read).with_indifferent_access
    end
  end


  post '/add_product' do
    body = @payload['products']
    api = Bigcommerce::Api.new({
                                   :store_url => "https://store-auiautt3.mybigcommerce.com",
                                   :username => "rahman-11",
                                   :api_key => "ab2290273590c54591c60ea363b98cc723d361b7"
                               })
    headers = {"Content-Type" => "application/json", 'Accept' => 'application/json'}

    body.each do |product_options|
         response = Service.request_bigapp :post, "/products", product_options, headers, api
         puts response
      end
  end

  post '/get_products' do
    body = @payload['products']
    api = Bigcommerce::Api.new({
                                   :store_url => "https://store-auiautt3.mybigcommerce.com",
                                   :username => "rahman-11",
                                   :api_key => "ab2290273590c54591c60ea363b98cc723d361b7"
                               })
    headers = {"Content-Type" => "application/json", 'Accept' => 'application/json'}

    body.each do |product_options|
      response = Service.request_bigapp :get, "/products", product_options, headers, api
      puts response
      response.each do |get_res|
        "Received" + get_res['name'] + "product"
      end

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

  def self.request_bigapp(method, path, options, headers={}, api)
    @config = api.connection.configuration
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
      {}
    elsif response.code == 409
      exception = JSON.parse response
      exception.each do |response_error|
        # raise ResponseError, "#{response.code}, Api Error:" +  response_error['details']['conflict_reason']
        return response_error['details']['conflict_reason']
      end
    end
  end


  def self.request(method, body, api)


    response = HTTParty.post("http://push.wombat.co", body: body.to_json, headers:
                                                        {
                                                            "X-Hub-Access-Token" => "7ce9ba94011c45b0e44c9a0f6e9e55102828ec3edd6e8dfc",
                                                            "X-Hub-Store" => "555d5ba2736d61639cf50100",
                                                            "Content-Type" => "application/json"
                                                        })

    return response if response.code == 200 || 202
    puts response
    raise ResponseError, "#{response.code}, API error: #{response.body.inspect}"
  end

  class ResponseError < StandardError;
  end


end

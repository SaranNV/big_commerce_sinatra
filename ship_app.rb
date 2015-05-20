require 'sinatra'
require 'httparty'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'
require 'base64'
require 'unirest'

Unirest.timeout(240)

class ShipApp < Sinatra::Base
  attr_reader :payload


  before do
    @payload = JSON.parse(request.body.read).with_indifferent_access
  end


  post '/test_shipment' do

    # payload = "{\"shipment\":[{\"id\":\"111\",\"order_id\":\"R154085346\",\"email\":\"spree@example.com\",\"cost\":5,\"status\":\"shipped\",\"stock_location\":\"default\",\"shipping_method\":\"UPS Ground (USD)\",\"tracking\":\"12345678\",\"updated_at\":"",\"shipped_at\":\"2014-02-03T17:33:55.343Z\"}]}"
    payload = @payload

    options = {
        headers: {"Content-Type" => "application/json", "X-Hub-Store" => "5551e429736d6164084f0000", "X-Hub-Access-Token" => "ef72138b58869394a224dad3ce90d4e5ae677d4eaaa6a891"},
        parameters: payload
    }

    puts options

    response = Service.request :post, options
    "Shipment transmitted to ShipStation: #{payload['shipments']['order_id']}"
  end

  post "/get_shipments" do
    content_type :json
    request_id = payload[:request_id]



    shipments = Service.new(payload).shipments_since
    {request_id: request_id, shipments: shipments}.to_json
  end

  post "/add_shipment" do
    content_type :json
    request_id = payload[:request_id]



    shipment = Service.new(payload).create
    {request_id: request_id, summary: "Shipment #{shipment} was added"}.to_json
  end

  post "/update_shipment" do
    content_type :json
    request_id = payload[:request_id]

    shipment = Service.new(payload).update
    {request_id: request_id, summary: "Shipment #{shipment} was updated"}.to_json
  end

  post "/get_picked_up" do
    content_type :json
    request_id = payload[:request_id]

    shipments = Service.new(payload).picked_up
    {request_id: request_id, shipments: shipments}.to_json
  end

  # Custom webhook
  post "/cancel_shipment" do
    content_type :json
    request_id = payload[:request_id]

    shipment = Service.new(payload).cancel
    {request_id: request_id, summary: "Shipment #{shipment} was canceled"}.to_json
  end
end


class Service
  attr_reader :payload

  def initialize(payload = {})
    @payload = payload
  end


  # Search for shipments after a given timestamp, e.g. payload[:created_after]
  def shipments_since
    [
        {
            "id" => "111",
            "status" => "shipped",
            "tracking" => "222"
        }
    ]
  end

  # Talk to your shipment api, e.g.
  #   FedEx.get_picked_up payload
  def picked_up
    [
        {"id" => "12836", "status" => "picked_up", "picked_up_at" => "2014-02-03T17:29:15.219Z"},
        {"id" => "13243", "status" => "picked_up", "picked_up_at" => "2014-02-03T17:03:15.219Z"}
    ]
  end

  # Talk to your shipment api, e.g.
  #   FedEx.create_shipment payload
  def create
    payload[:shipment][:id]
  end

  # Talk to your shipment api, e.g.
  #   FedEx.create_shipment payload
  def update
    payload[:shipment][:id]
  end

  # Talk to your shipment api, e.g.
  #   FedEx.cancel_shipment payload
  def cancel
    payload[:shipment][:id]
  end


  def self.request(method,options)
    base_uri = "https://push.wombat.co"
    # response = HTTParty.post("http://api.neemtecsolutions.com/new_product.php", options)
    options = {
        "shipments"=>[
            {
                "id"=>"12836251406",
                "order_id"=>"R154085346",
                "email"=>"spree@example.com",
                "cost"=>5,
                "status"=>"ready",
                "stock_location"=>"default",
                "shipping_method"=>"UPS Ground (USD)",
                "tracking"=>"12345678",
                "shipped_at"=>"2014-02-03T17:33:55.343Z",
                "channel"=>"spree",
                "totals"=>{
                    "item"=>200,
                    "adjustment"=>10,
                    "tax"=>10,
                    "shipping"=>0,
                    "payment"=>210,
                    "order"=>210
                },
                "shipping_address"=>{
                    "firstname"=>"Joe",
                    "lastname"=>"Smith",
                    "address1"=>"1234 Awesome Street",
                    "address2"=>"",
                    "zipcode"=>"90210",
                    "city"=>"Hollywood",
                    "state"=>"California",
                    "country"=>"US",
                    "phone"=>"0000000000"
                },
                "billing_address"=>{
                    "firstname"=>"Joe",
                    "lastname"=>"Smith",
                    "address1"=>"1234 Awesome Street",
                    "address2"=>"",
                    "zipcode"=>"90210",
                    "city"=>"Hollywood",
                    "state"=>"California",
                    "country"=>"US",
                    "phone"=>"0000000000"
                },
                "items"=>[
                    {
                        "name"=>"Spree T-Shirt",
                        "product_id"=>"SPREE-T-SHIRT",
                        "quantity"=>1,
                        "price"=>30,
                        "options"=>{}
                    }
                ]
            }
        ]
    }
    response = HTTParty.post("https://push.wombat.co", options)
    # response = Unirest.send method, "http://api.neemtecsolutions.com/#{path}", options

    return response if response.code == 200

    puts response

    raise ResponseError, "#{response.code}, API error: #{response.body.inspect}"
  end

  class ResponseError < StandardError;
  end


end

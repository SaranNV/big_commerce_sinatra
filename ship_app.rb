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

    body = @payload
    response = Service.request :post, body
    "Shipment transmitted to ShipStation: #{body['shipments'][0]['order_id']}"
  end

  post '/test_add_product' do
    body = @payload

    response = Service.request :post, body
    puts response
    "Product #{body['product'][0]['name']}"
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


  def self.request(method,body)


    response = HTTParty.post("http://push.wombat.co", body: body.to_json, headers:
                                                        {
                                 "X-Hub-Access-Token"=> "7ce9ba94011c45b0e44c9a0f6e9e55102828ec3edd6e8dfc",
                                 "X-Hub-Store"=> "555d5ba2736d61639cf50100",
                                 "Content-Type"=> "application/json"
                             })
    return response if response.code == 200 || 202
    puts response
    raise ResponseError, "#{response.code}, API error: #{response.body.inspect}"
  end

  class ResponseError < StandardError;
  end


end

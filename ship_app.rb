require 'sinatra'
require 'httparty'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'


class ShipApp < Sinatra::Base
  attr_reader :payload


  before do
    @payload = JSON.parse(request.body.read).with_indifferent_access
  end


  post '/test_shipment' do

    payload = @payload
    options = {
        headers: { "Content-Type" => "application/json", "X-Hub-Store" => "5551e429736d6164084f0000", "X-Hub-Access-Token" => "ef72138b58869394a224dad3ce90d4e5ae677d4eaaa6a891", "X-Hub-Timestamp" => Time.now.utc.to_i.to_s},
        parameters: payload.to_json
    }

    response = Service.request :post,  options
    result 200, "Shipment transmitted to ShipStation: #{response.body["orderId"]}"
  end

  post "/get_shipments" do
    content_type :json
    request_id = payload[:request_id]

    shipments = Service.new(payload).shipments_since
    { request_id: request_id, shipments: shipments }.to_json
  end

  post "/add_shipment" do
    content_type :json
    request_id = payload[:request_id]

    shipment = Service.new(payload).create
    { request_id: request_id, summary: "Shipment #{shipment} was added" }.to_json
  end

  post "/update_shipment" do
    content_type :json
    request_id = payload[:request_id]

    shipment = Service.new(payload).update
    { request_id: request_id, summary: "Shipment #{shipment} was updated" }.to_json
  end
  
  post "/get_picked_up" do
    content_type :json
    request_id = payload[:request_id]

    shipments = Service.new(payload).picked_up
    { request_id: request_id, shipments: shipments }.to_json
  end

  # Custom webhook
  post "/cancel_shipment" do
    content_type :json
    request_id = payload[:request_id]

    shipment = Service.new(payload).cancel
    { request_id: request_id, summary: "Shipment #{shipment} was canceled" }.to_json
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
        "id" => "12836",
        "status" => "shipped",
        "tracking" => "12345678"
      }
    ]
  end

  # Talk to your shipment api, e.g.
  #   FedEx.get_picked_up payload
  def picked_up
    [
      { "id" => "12836", "status" => "picked_up", "picked_up_at" => "2014-02-03T17:29:15.219Z" },
      { "id" => "13243", "status" => "picked_up", "picked_up_at" => "2014-02-03T17:03:15.219Z" }
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


  def self.request(method, options)
     base_uri = "https://push.wombat.co"
    response = HTTParty.post("https://push.wombat.co", options)

    return response if response.code == 200

    raise ResponseError, "#{response.code}, API error: #{response.body.inspect}"
  end

  class ResponseError < StandardError; end


end

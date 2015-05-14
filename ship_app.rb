require 'sinatra'
require 'httparty'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'

class ShipApp < Sinatra::Base
  attr_reader :payload


  before do
    @payload = JSON.parse(request.body.read).with_indifferent_access
  end

  get "/ship_app" do
    "Welcome ShipApp"
  end

  post "/test_shipment" do
    json_payload = @payload
    base_uri = 'https://push.wombat.co'
    res = HTTParty.post((base_uri),
        {
            body: json_payload,
            headers: {
                'Content-Type'       => 'application/json',
                'X-Hub-Store'        => '5551e429736d6164084f0000',
                'X-Hub-Access-Token' => 'ef72138b58869394a224dad3ce90d4e5ae677d4eaaa6a891',
                'X-Hub-Timestamp'    => Time.now.utc.to_i.to_s
            }
        }
    ).to_json

    validate(res)

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
  def validate(res)
    raise PushApiError, "Push not successful. Wombat returned response code #{res.code} and message: #{res.body}" if res.code != 202
  end
end

class PushApiError < StandardError; end

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
end

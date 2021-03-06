require 'rack'
require 'byebug'
require_relative '../lib/rails_lite_server/controller_base'

class MyController < ControllerBase
  def go
    session["count"] ||= 0
    session["count"] += 1
    flash.now[:errors] = ["aowein"]
    flash[:errors] = ["snitches get stitches"]
    render :counting_show
  end
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  MyController.new(req, res).go
  res.finish
end

Rack::Server.start(
  app: app,
  Port: 3000
)

require 'rack'
require 'json'
require 'cgi'
require_relative '../lib/controller_base'

class MyController < ControllerBase
  def go
    render :show
  end
end

class CatchException
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue Exception => e
      res = Rack::Response.new
      res.status = 505
      res.write(error_html(e))
      res.finish
    end
  end

  def error_html(error)
    ret_html = "<h1>#{error.class.name}</h1>\n"
    ret_html << "<h3>#{error.message}</h3>\n"
    ret_html << "<table>\n"
    error.backtrace.each do |back_line|
      ret_html << "<tr><td>#{ CGI::escapeHTML(back_line) }</td></tr>\n"
    end
    ret_html << "</table>\n"
    ret_html
  end
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  MyController.new(req, res).go
  res.finish
end

broken_app = Rack::Builder.new do
  use CatchException
  run app
end

Rack::Server.start(
  app: broken_app,
  Port: 3000
)

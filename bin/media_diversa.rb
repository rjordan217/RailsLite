require 'rack'

class MediaRender
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    res = Rack::Response.new
    if req.path =~ /\/public\/*/
      phyllo_nom, extension = req.path.scan(/\/([^\/\s]*)\.(\w{3})/).flatten
      res['Content-Type'] = case extension
      when 'jpg'
        'image/jpeg'
      when 'mp3'
        'audio/mp3'
      when 'mp4'
        'video/mp4'
      else
        nil
      end
      if res['Content-Type']
        phyllo = File.read("#{Dir.pwd}/public/#{phyllo_nom}.#{extension}")
        res.write(phyllo)
        res.status = 200
        res.finish
      else
        res['Content-Type'] = 'text/html'
        res.status = 405
        res.write("<h1>Error</h1>\n<p>Could not access data type '#{extension}'</p>")
        res.finish
      end
    else
      @app.call(env)
    end
  end
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  res['Content-Type'] = 'text/html'

  res.write(req.cookies)
  res.finish
end

principale = Rack::Builder.new do
  use MediaRender
  run app
end.to_app

Rack::Server.start(
  app: principale,
  Port: 3000
)

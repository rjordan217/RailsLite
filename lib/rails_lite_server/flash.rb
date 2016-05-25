class Flash
  attr_accessor :now
  def initialize(req)
    cook = req.cookies['_rails_lite_app'] || Hash.new {[]}
    @now = JSON.parse(cook.to_s)
    @next_req = Hash.new {[]}
  end

  def [](key)
    @now[key.to_s]
  end

  def []=(key,val)
    @next_req[key.to_s] = val
  end

  def store_flash(res)
    unless @next_req.empty?
      res.set_cookie(
        '_rails_lite_app',
        {
          path: '/',
          value: @next_req.to_json
        }
      )
    end
  end
end

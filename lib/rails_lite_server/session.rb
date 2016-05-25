require 'json'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    cook = req.cookies['_rails_lite_app'] || Hash.new
    @cookie = JSON.parse(cook.to_s)
  end

  def [](key)
    @cookie[key]
  end

  def []=(key, val)
    @cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.set_cookie(
      '_rails_lite_app',
      {
        path: '/',
        value: @cookie.to_json
      }
    )
  end
end

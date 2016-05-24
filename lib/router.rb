class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name, :id

  def initialize(pattern, http_method, controller_class, action_name)
    @http_method = http_method
    @pattern = pattern
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    req.path =~ self.pattern && req.request_method =~ /#{http_method}/i
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    scanned_path = req.path.scan(/\/\d+/).first
    if scanned_path
      extra_params = Hash.new
      extra_params["id"] = scanned_path.delete!("/")
    else
      extra_params = {}
    end
    new_controller = controller_class.new(req, res, extra_params)
    new_controller.invoke_action(action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
    p self.methods - Object.methods
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    puts "Inside method defining action"
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
    puts "Completed"
  end

  # should return the route that matches this request
  def match(req)
    @routes.each do |route|
      return route if route.matches?(req)
    end
    nil
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    ruta = match(req)
    if ruta
      ruta.run(req, res)
    else
      res.status = 404
    end
  end
end

require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative 'session'
require_relative 'flash'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, extra_params = {})
    @req = req
    @res = res
    @params = req.params.merge(extra_params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    unless already_built_response?
      @res.status = 302
      @res['location'] = url
      session.store_session(@res)
      flash.store_flash(@res)
      @already_built_response = true
    else
      raise "Response already built"
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    unless already_built_response?
      @res.write(content)
      @res['Content-Type'] = content_type
      session.store_session(@res)
      flash.store_flash(@res)
      @already_built_response = true
    else
      raise "Response already built"
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    clase = self.class.name.underscore
    locale = "/#{clase}/#{template_name}"
    @res['location'] = locale
    @res.status = 200
    file_with_erb = File.read(Dir.pwd + "/views#{locale}.html.erb")
    html_erb = ERB.new(file_with_erb)
    render_content(html_erb.result(binding), 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  def flash
    @flash ||= Flash.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
  end
end

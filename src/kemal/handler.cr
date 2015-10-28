require "http/server"
require "uri"

class Kemal::Handler < HTTP::Handler
  INSTANCE = new

  def initialize
    @routes = [] of Route
  end

  def call(request)
    response = exec_request(request)
    response || call_next(request)
  end

  def add_route(method, path, &handler : Kemal::Context -> _)
    @routes << Route.new(method, path, &handler)
  end

  def exec_request(request)
    components = request.path.not_nil!.split "/"
    @routes.each do |route|
      match = route.match?(request)
      if match
        params = Kemal::ParamParser.new(route, request).parse
        context = Context.new(request, params.not_nil!)
        begin
          body = route.handler.call(context).to_s
          content_type = context.content_type
          return HTTP::Response.ok(content_type, body)
        rescue ex
          return HTTP::Response.error("text/plain", ex.to_s)
        end
      end
    end
    nil
  end
end
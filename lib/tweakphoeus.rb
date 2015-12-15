require "tweakphoeus/version"
require "typhoeus"

class Tweakphoeus
  attr_accessor :cookie_jar

  def initialize()
      @cookie_jar = {}
  end

  def get url, body: nil, header: nil
    inject_cookies url, header
    response = Typhoeus.get url, body: body, headers: header
    obtain_cookies response
    response = get(redirect_url(response), body, header) if has_redirect?(response)
    response
  end

  def post url, body: nil, header: nil
    inject_cookies url, header
    response = Typhoeus.get url, body: body, headers: header
    obtain_cookies response
    response = post(redirect_url(response), body, header) if has_redirect?(response)
    response
  end

  def get_hide_inputs response
    #TODO
  end



  private

  def obtain_cookies response
    set_cookies_field = response.headers["Set-Cookie"]
    if set_cookies_field.class == "String"
      set_cookies_field = [set_cookies_field]
    end

    set_cookies_field.each do |cookie|
      fields = cookie.split("; ")
      puts fields.to_s
      case fields.count
      when 5
        value, expire, path, domain, only = fields
      when 4
        value, path, domain, only = fields
      else
        puts "Wtf?!"
        raise StandardException("bad number of cookie fields")
      end
      key, value = value.split("=")
      domain = domain.split("=").last
      @cookie_jar = {} if @cookie_jar.nil? #TODO remove after debug
      @cookie_jar[domain] = [] if @cookie_jar[domain].nil?
      @cookie_jar[domain] << {key => value}
    end
  end

  def inject_cookies url, headers
    url = url.gsub("www.","").split("/")
    headers = {} if headers.nil?
    cookies = []
    while url.split(".").count > 1
       cookies << @cookie_jar[url] if @cookie_jar[url]
       cookies << @cookie_jar["." + url] if @cookie_jar["." + url]
       url = url.split(".")[1..-1].join(".")
    end

    headers["Set-Cookie"] = cookies.flatten
  end

  def has_redirect? response
    redirect_url(response).nil?
  end

  def redirect_url response
    response.headers["Location"]
  end
end

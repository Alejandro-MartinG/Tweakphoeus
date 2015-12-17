require "tweakphoeus/version"
require "typhoeus"

module Tweakphoeus
  class Client
    attr_accessor :cookie_jar

    def initialize()
      @cookie_jar = {}
    end

    def imp #TODO: debugged method
      @cookie_jar
    end

    def get url, body: nil, headers: nil, redirect: true
      inject_cookies url, headers
      response = Typhoeus.get url, body: body, headers: headers
      obtain_cookies response
      response = get(redirect_url(response), body: body, headers: headers) if redirect && has_redirect?(response)
      response
    end

    def post url, body: nil, headers: nil, redirect: false
      inject_cookies url, headers
      response = Typhoeus.post url, body: body, headers: headers
      obtain_cookies response
      response = post(redirect_url(response), body: body, headers: headers) if redirect && has_redirect?(response)
      response
    end

    def get_hide_inputs response
      #TODO
    end

    def add_cookies host, key, value
      domain = get_domain host
      @cookie_jar[domain] = [] if @cookie_jar[domain].nil?
      @cookie_jar[domain] = @cookie_jar[domain].reject{|hash| hash.first[0]==key}
      @cookie_jar[domain] << {key => value}
    end

    def get_domain domain
      domain.match(/([a-zA-Z0-9]+:\/\/|)([^\/]+)/)[2]
    end

    private

    def obtain_cookies response
      set_cookies_field = response.headers["Set-Cookie"]
      return if set_cookies_field.nil?
      if set_cookies_field.is_a?(String)
        set_cookies_field = [response.headers["Set-Cookie"]]
      end

      set_cookies_field.each do |cookie|
        key, value = cookie.match(/^([^=]+)=(.+)/).to_a[1..-1]
        domain = cookie.match(/Domain=\.([^;]+)/)

        if domain.nil?
          domain = get_domain response.request.url
        else
          domain = domain[1]
        end

        if value != "\"\""
          @cookie_jar[domain] = [] if @cookie_jar[domain].nil?
          @cookie_jar[domain] = @cookie_jar[domain].reject{|hash| hash.first[0]==key}
          @cookie_jar[domain] << {key => value}
        end
      end
    end

    def inject_cookies url, headers
      domain = get_domain url
      headers = {} if headers.nil?
      cookies = []

      while domain.split(".").count > 1
        if @cookie_jar[domain]
          @cookie_jar[domain].each do |cookie|
            if !cookie.in?(cookies.map{|k,v| k})
              cookies << cookie
            end
          end
        end
        domain = domain.split(".")[1..-1].join(".")
      end

      headers["Cookie"] = cookies.map{|hash| hash.map{|k,v| k + "=" + v}}.flatten.join('; ')
    end

    def has_redirect? response
      !redirect_url(response).nil?
    end

    def redirect_url response
      response.headers["Location"]
    end

    def purge_bad_cookies cookies
      cookies.reject{|e| e.first.last=="\"\""}
    end
  end
end

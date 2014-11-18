class Url

  # https://url.spec.whatwg.org/#percent-encoded-bytes
  BASE_ENCODE_SET = '([\uD800-\uDBFF][\uDC00-\uDFFF])|[^\u0020-\u007E]'
  SIMPLE_ENCODE_SET = RegExp.new(BASE_ENCODE_SET, 'g')
  PASSWORD_ENCODE_SET = RegExp.new(BASE_ENCODE_SET + "|[\\@/]", 'g')
  USERNAME_ENCODE_SET = RegExp.new(BASE_ENCODE_SET + "|[\\@/:]", 'g')

  DEFAULT_ENCODE_SET = RegExp.new(BASE_ENCODE_SET + '|[\u0020"#<>?]', 'g')

  QUERY_ENCODE_SET = RegExp.new(BASE_ENCODE_SET + '|[\x20\x23\x3C\x3E\x60]', 'g')

  # https://url.spec.whatwg.org/#relative-scheme
  DEFAULT_PORT = {
    "ftp" => "21",
    "file" => nil,
    "gopher" => "70",
    "http" => "80",
    "https" => "443",
    "ws" => "80",
    "wss" => "443"
  }
  RELATIVE_SCHEME = DEFAULT_PORT.keys()

  # https://url.spec.whatwg.org/#url-code-points
  URL_CODE_POINTS = /[a-zA-Z0-9
    !$&'()*+,\-.\/:;=?@_~
    \u00A0-\uD7FF \uE000-\uFDCF \uFDF0-\uFFFD
    \u{10000}-\u{1FFFD} \u{20000}-\u{2FFFD} \u{30000}-\u{3FFFD}
    \u{40000}-\u{4FFFD} \u{50000}-\u{5FFFD} \u{60000}-\u{6FFFD}
    \u{70000}-\u{7FFFD} \u{80000}-\u{8FFFD} \u{90000}-\u{9FFFD}
    \u{A0000}-\u{AFFFD} \u{B0000}-\u{BFFFD} \u{C0000}-\u{CFFFD}
    \u{D0000}-\u{DFFFD} \u{E0000}-\u{EFFFD} \u{F0000}-\u{FFFFD}
    \u{100000}-\u{10FFFD}
  ]/x

  def self.utf8_percent_encode(codepoint)
    # TODO: compare against WHATWG spec
    enc = nil
    c1 = codepoint.charCodeAt(0)

    if c1 < 128
      enc = [c1]
    elsif c1 > 127 && c1 < 2048
      enc = [
        (c1 >> 6) | 192, (c1 & 63) | 128
      ]
    elsif (c1 & 0xF800) != 0xD800
      enc = [
        (c1 >> 12) | 224, ((c1 >> 6) & 63) | 128, (c1 & 63) | 128
      ]
    else
      # surrogate pairs
      c2 = codepoint.charCodeAt(1)

      if (c1 & 0xFC00) != 0xD800 or (c2 & 0xFC00) != 0xDC00
        # unmatched surrogate pair
        enc = [
          (c1 >> 12) | 224, ((c1 >> 6) & 63) | 128, (c1 & 63) | 128
        ]
      else
        c1 = ((c1 & 0x3FF) << 10) + (c2 & 0x3FF) + 0x10000
        enc = [
          (c1 >> 18) | 240, ((c1 >> 12) & 63) | 128,
          ((c1 >> 6) & 63) | 128, (c1 & 63) | 128
        ]
      end
    end

    result = ""

    if enc != nil
      for i in 0...enc.length
        result += "%" + (Math.floor(enc[i]/16)).toString(16) +
          (enc[i]%16).toString(16)
      end
    end

    return result.toUpperCase()
  end

  # https://url.spec.whatwg.org/#percent-decode
  def self.percent_decode(input)
    warn = null;

    if input =~ /%($|[^0-9a-fA-F]|.$|.[^0-9a-fA-F])/
      warn = 'Percent sign ("%") not followed by two hexadecimal digits'
    end

    # collapsed steps 1..3
    result = input.gsub(/%[0-9a-fA-F]{2}/) {|c| c[1..-1].to_i(16).chr}

    if warn
      result = String.new(result)
      result.exception = warn
    end

    return result
  end

  def self.utf8_percent_decode(input)
    # TODO compare against WHATWG encoding
    return input.gsub(/(%[0-9a-fA-F]{2})+/) do |chars|
      bytes = []
      (0...chars.length).step(3) do |i|
              bytes << chars[i+1..i+2].to_i(16)
      end

      chars = ''
      while bytes.length>0
        if bytes[0] < 0x80
          chars += String.fromCharCode(bytes.shift())
        elsif bytes[0] < 0xC2
          chars += '%' + bytes.shift().to_s(16).upcase() # error
        elsif bytes[0] < 0xE0
          if bytes.length == 1
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif (bytes[1] & 0xC0) != 0x80
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          else
            chars += String.fromCharCode((bytes.shift() << 6) +
                    bytes.shift() - 0x3080)
          end
        elsif bytes[0] < 0xF0
          if bytes.length <= 2
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif (bytes[1] & 0xC0) != 0x80
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif (bytes[1] & 0xC0) != 0x80
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif bytes[0] == 0xE0 && bytes[1] < 0xA0
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif (bytes[2] & 0xC0) != 0x80
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          else
            chars += String.fromCharCode((bytes.shift() << 12) +
                   (bytes.shift() << 6) + bytes.shift() - 0xE2080)
          end
        elsif bytes[0] < 0xF5
          if bytes.length <= 3
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif (bytes[1] & 0xC0) != 0x80
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif bytes[0] == 0xF0 && bytes[1] < 0x90
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif bytes[0] == 0xF4 && bytes[1] >= 0x90
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif (bytes[2] & 0xC0) != 0x80
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          elsif (bytes[3] & 0xC0) != 0x80
            chars += '%' + bytes.shift().to_s(16).upcase() # error
          else
            chars += String.fromCharCode((bytes.shift() << 18) +
                    (bytes.shift() << 12) + (bytes.shift() << 6) +
                    bytes.shift() - 0x3C82080)
          end
        else
          chars += '%' + bytes.shift().to_s(16).upcase() # error
        end
      end
      chars
    end
  end

  # https://url.spec.whatwg.org/#utf-8-percent-encode
  def self.percent_encode(string, encode_set)
    return string.gsub encode_set do |code_point|
      Url.utf8_percent_encode(code_point)
    end
  end

  def self.path_concat(base, path)
    base = (base ? base.slice(0) : [])

    if path[0] == '.'
      path.shift()
      base.pop()
    end

    if path.length == 1 and path[0] == ''
      path=base
    elsif path.length > 1 and path[0] == ''
      path.shift()
    else
      base.pop()
      path = base.concat(path)
    end

    return path
  end

  # https://url.spec.whatwg.org/#host-parsing
  def host_parser(input, unicode_flag=nil)
    # 1
    raise Failure, 'empty host' if input == ''

    # 2
    if input.start_with? '['

      # 2.1
      if not input.end_with? ']'
        @parse_error = true
        raise Failure, 'unmatched brackets in host'
      end

      # 2.2
      return IPAddr.new(input[1...-1])
    end

    # 3
    domain = percent_decode(input.encode(Encoding::UTF_8)).
      encode(Encoding::UTF_8)

    begin
      # 4
      uri = Addressable::URI.new
      uri.host = domain
      asciiDomain = uri.normalized_host
    rescue => e
      # 5
      raise Failure, "invalid domain - #{e}"
    end

    # 6
    if
      asciiDomain.chars.any? do |c|
        "\u0000\u0009\u000A\u0020#%/:?@[\\]".include? c
      end
    then
      raise Failure, 'invalid domain - reserved characters'
    end

    # 7
    if unicode_flag
      return asciiDomain
    else
      return asciiDomain # TODO:
      # https://url.spec.whatwg.org/#concept-domain-to-unicode
    end
  end

  # https://url.spec.whatwg.org/#concept-host-serializer
  def host_serializer(host)

    # 1
    return '' if host.nil?

    # 2
#   return "[#{host.to_s}]" if IPAddr === host

    # 3
    return host
  end

  # https://url.spec.whatwg.org/#concept-ipv6-serializer
  # http://tools.ietf.org/html/rfc5952#section-4
  def self.canonicalize_ipv6(pre, post=[], ipv4=nil)
    slots = (ipv4 ? 6 : 8)
    pre << '0' while pre.length + post.length < slots
    pre = pre.concat post
    pre.map! {|n| n.to_i(16).to_s(16).upcase()}

    zero = nil
    for i in 0 .. slots-2
      if pre[i] == '0' and pre[i] == '0'
        zero = i
        break
      end
    end

    if not zero
      post = nil
    else
      post = pre[zero+1..-1]
      pre = pre.first(zero)
      post.shift() while post.length > 1 and post[0] == '0'
      post = nil if ipv4 and post.length == 1 and post[0] == '0'
    end

    result = pre.join(':')
    result += '::' + post.join(':') if post
    result += '::' + ipv4 if ipv4

    return result
  end

  attr_accessor :scheme, :scheme_data, :host
  attr_accessor :path, :query, :fragment, :exception

  def initialize(input, base)
    begin
      base = UrlParser.parse(base) if base
      input.sub! /^[\u0009\u000A\u000C\u000D\u0020]+/, ''
      input.sub! /[\u0009\u000A\u000C\u000D\u0020]+$/, ''
      url = UrlParser.parse(input, base: base)

      @scheme = ''
      @scheme_data = ''
      @username = ''
      @password = nil
      @host = nil
      @port = ''
      @path = []
      @query = nil
      @fragment = nil

      for property in url
        this["_#{property}"] = url[property]
      end
    rescue => e
      @href = input
      @exception = e.message
    end
  end

  # https://url.spec.whatwg.org/#url-serializing
  def serializer(exclude_fragment=false)

    # 1
    output = "#@scheme:"

    # 2
    if not @scheme_data

      # 2.1
      output += '//'

      # 2.2
      if @username != '' or @password != nil

        # 2.2.1
        output += @username || ''

        # 2.2.2
        output += ":#@password" unless @password == nil

        # 2.2.3
        output += '@'
      end

      # 2.3
      output += host_serializer(@host)

      # 2.4
      output += ":#@port" unless @port.empty?

      # 2.5
      output += "/" + @path.join('/')

    # 3
    else
      output += @scheme_data
    end

    # 4
    output += "?#@query" unless @query.nil?

    # 5
    output += "##@fragment" if not @fragment.nil? and not exclude_fragment

    # 6
    return output

  end

  # https://url.spec.whatwg.org/#dom-url-href
  def href
    @href || self.serializer()
  end

  def href=(value)
    begin
      oldhref = @href
      oldexception = @exception
      Url.apply(this, [value, null]);
    ensure
      # @href is only set when there is an error.  If there previously was
      # an error, restore it.  If there is a new error, ignore it.
      @href = oldhref
      @exception = oldexception
    end
  end

  # https://url.spec.whatwg.org/#dom-url-protocol
  def protocol
    @scheme ? "#@scheme:" : ':'
  end

  def protocol=(value)
    begin
      UrlParser.parse(value, url: this, startRule: 'setProtocol')
    rescue => e
    end
  end

  # https://url.spec.whatwg.org/#dom-url-username
  def username
    @username ? @username : ''
  end

  def username=(value)
    begin
      UrlParser.parse(value, url: this, startRule: 'setUsername')
    rescue => e
      console.log(e)
    end
  end

  # https://url.spec.whatwg.org/#dom-url-password
  def password
    @password ? @password : ''
  end

  # https://url.spec.whatwg.org/#dom-url-hostname
  def hostname
    self.host_serializer(@host)
  end

  # https://url.spec.whatwg.org/#dom-url-port
  def port
    @port ? @port : ''
  end

  # https://url.spec.whatwg.org/#dom-url-pathname
  def pathname
    return '' unless @scheme
    @scheme_data || ('/' + @path.join('/'))
  end

  # https://url.spec.whatwg.org/#dom-url-search
  def search
    return '' if @query.nil? or @query.empty?
    return "?#@query"
  end

  # https://url.spec.whatwg.org/#dom-url-hash
  def hash
    return '' if @fragment.nil? or @fragment.empty?
    return "##@fragment"
  end
end

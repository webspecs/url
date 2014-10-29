{
  base = options.base || {scheme: 'about'}

  /* This function accepts a variable number of arguments.  It copies the
     'exception' property from the first object which defines such to
     the first object.  It then returns the first object */
  function copy(base) {
    var result = base;
    if (!result.exception) {
      for (var i = 1; i<arguments.length; i++) {
        if (arguments[i] && arguments[i].exception) {
          result.exception = arguments[i].exception;
          break;
        }
      }
    };
    return result
  }

  /* exceptions which aren't (yet?) defined in the WHATWG spec */
  function extension_exception(value) {
    this.value = value || '';
    this.length = this.value.length;
    this.extension = true;
  };
  extension_exception.prototype = new String;
  extension_exception.prototype.toString = 
    extension_exception.prototype.valueOf = function() {return this.value}

  /* cleanse a url component given a encode set */
  function cleanse(string, encode_set, component) {
    warn = null;

    for (var i=0; i<string.length; i++) {
      if (/^[\u0009\u000A\u000D]$/.test(string[i])) {
        warn = "Tab, new line, or cariage return found in " + component
        string.splice(i--, 1)
      }
    }

    if (string.some(function(c) {
      return c != '%' && !Url.URL_CODE_POINTS.test(c)
    })) {
      warn = "Illegal character in " + component;
    };

    string = Url.percent_encode(string.join(''), encode_set)

    if (warn) {
      string = new String(string);
      string.exception = warn;
    };

    return string
  }
}

/*
   There are four unique syntaxes for
   <a href="https://url.spec.whatwg.org/#concept-url">URL</a>s,
   each returning a set of components, namely one or more of the following:
   <a href="https://url.spec.whatwg.org/#concept-url-scheme">scheme</a>,
   <a href="https://url.spec.whatwg.org/#concept-url-scheme-data">scheme_data</a>,
   <a href="https://url.spec.whatwg.org/#concept-url-username">username</a>,
   <a href="https://url.spec.whatwg.org/#concept-url-password">password</a>,
   <a href="https://url.spec.whatwg.org/#concept-url-host">host</a>,
   <a href="https://url.spec.whatwg.org/#concept-url-port">port</a>,
   <a href="https://url.spec.whatwg.org/#concept-url-path">path</a>,
   <a href="https://url.spec.whatwg.org/#concept-url-query">query</a>, and
   <a href="https://url.spec.whatwg.org/#concept-url-fragment">fragment</a>.

   In the case of a @RelativeUrl, the $result object to be returned is
   initialized to the value returned by @RelativeUrl, and then modify it as
   follows before being returned:
     * Set $result.scheme to $base.scheme.
     * Set $result.host to $base.host.
     * Replace $result.path by the <a>path concatenation</a> of $base.path and
       $result.Path.

   In all other cases, the value returned by the called production is returned
   unmodified.
*/
Url
  = FileLikeRelativeUrl
  / AbsoluteUrl
  / NonRelativeUrl
  / result:RelativeUrl
  {
    result.scheme = base.scheme;
    result.host = base.host; 
    result.path = Url.path_concat(base.path, result.path)

    return result
  }
  // comment

/*
   Four production rules are defined for files, numbered from top to bottom.

   Evaluation instructions for each:

   <ol>
   <li>Set $result to the object returned by
   @RelativeUrl, and then modify it as follows:

     * Set $result.scheme to the value returned by
       @FileLikeRelativeScheme.
     * Remove the first element from $result.path if it is an empty
       string and if there is a second element which has a non-empty value.
     * Construct a string using the alphabetic
       character following the first ":" in the input
       concatenated with a ":".  Prepend this string to 
       $result.path.

   <li>Indicate a <a>parse error</a>.

   Set $result to the object returned by
   @RelativeUrl, and then modify it as follows:

     * Set $result.scheme to "file".
     * Remove the first element from $result.path if it is an empty
       string and if there is a second element which has a non-empty value.
     * Construct a string consisting of the character following
       the initial "/" (if any) in the production rule concatenated
       with a ":".  Prepend this string to the $result.path array.

   <li><em>This rule is only to be evaluated if the value of
   $base.scheme is "file"</em>.  Set $result to the object returned by
   @RelativeUrl, and then modify it as follows:

     * Set $result.scheme to "file".
     * Set $result.host to the value returned by the
       @Host production rule.
     * Remove the first element of the path if it is an empty string and
       there is a second element which has a non-empty value.

   <li>Set $result to the object returned by
   @RelativeUrl, and then modify it as follows:

     * Set $result.scheme to the value returned by
       @FileLikeRelativeScheme
     * If the @Host is present in the input, set $result.host
       to the value returned by the @Host production rule
     * If the @Host is not present and no slashes precede the
       @RelativeUrl in the input, then the $base.path
       minus the last element is prepended to the $result.path.

   </ol>

  Return $result.

  Note: at the present time, file like relative URLs are generally not
  interoperable, and therefore are effectively implementation defined.
  Furthermore, the parsing rules in this section have not enjoyed wide review,
  and therefore are more likely to be subject to change than other parts of this
  specification.
*/
FileLikeRelativeUrl
  = scheme:FileLikeRelativeScheme ':' 
    drive:[a-zA-Z] [:|]
    '/'? remainder:RelativeUrl
  {
    var result = remainder;
    result.scheme = scheme;
    if (result.path[0] == '' && result.path[1] != '') result.path.shift();
    result.path.unshift(drive+':');
    return result
  }

  / '/'*
    drive:[a-zA-Z] '|'
    '/'? remainder:RelativeUrl
  {
    var result = remainder;
    result.exception = 'Legacy compatibility issue';
    result.scheme = 'file';
    if (result.path[0] == '' && result.path[1] != '') result.path.shift();
    result.path.unshift(drive+':');
    return result
  }

  / &{ return base.scheme == 'file' }
    '/' '/' host:Host '/' remainder:RelativeUrl
  {
    var result = remainder
    result.scheme = 'file';
    result.host = host;
    if (result.path[0] == '' && result.path[1] != '') result.path.shift();
    return result
  }

  / scheme:FileLikeRelativeScheme ':' host:('/' '/' Host)? slash:'/'* remainder:RelativeUrl
  {
    var result = remainder;
    if (host) {
      result.host = host[2];
    } else if (slash.length == 0) {
      var path = base.path.slice(0, -1);
      path.push.apply(path, result.path);
      result.path = path
    }
    result.scheme = scheme;
    return result
  }

/*
  Only one "file like" relative scheme is defined at this time:
  "file".  This scheme is to be matched case insensitively.
  This production rule is to return the scheme value, lowercased.
*/
FileLikeRelativeScheme
  = scheme:"file"i
  {
    return scheme.toLowerCase()
  }

/*
   Two production rules are defined for absolute URLs, numbered from top to
   bottom.

   Evaluation instructions for each:

   <ol>
   <li>If anything other than two forward solidus characters ("//") immediately
     follows the first colon in the input, indicate a <a>parse error</a>.

     Set $result to the object returned by
     @RelativeUrl, and then modify it as follows:

     * If @RelativeScheme is present in the input, then
       set $result.scheme to this value, lowercased.
     * If @RelativeScheme is not present in the input, then
       set $result.scheme to the value of $base.scheme.
     * Set $result.host to the value returned by
       @Host up to the first "@" sign, if any.  If no
       "@" signs are present in the return value from the
       @Host production, then set $result.host to the
       entire value.
     * If one or more "@" signs are present in the value returned
       by the @Host production, then perform the following steps:
       * Indicate a <a>parse error</a>.
       * If the @UserInfo is not present in the input, then substitute
           `{"username": ""}` for the return value of
           @UserInfo in the remainder of this step.
       * If $password is present in the value for @UserInfo,
           replace it with "%40" repeated as many times as there are
           "@" signs in the value returned by @Host,
           concatenated with the value returned by @Host with
           all of the "@" signs removed.
       * If $password is not present in the @UserInfo,
           replace the $user in the @UserInfo with
           "%40" repeated as many times as there are "@"
           signs in the value returned by @Host, concatenated with
           the value returned by @Host with all of the
           "@" signs removed.
     * If @UserInfo is present (or computed per above), then
       perform the following steps:
       * If $result.Host is an empty string, then terminate parsing
           with a <a>parse error</a>.
       * Set $result.username to the $username value in the @UserInfo.
       * If $password is non-null in the @UserInfo, set
           $result.password to this value.
     * If the @Port is present and not equal to the
       <a href="https://url.spec.whatwg.org/#default-port">default port</a>
       that corresponds to the $response.scheme, then set 
       $result.port to this value.
         
   <li>Indicate a <a>parse error</a>.

    Initialize $result to be the value returned by @RelativeUrl, and then
    modify it as follows:

     * Set $result.scheme to value returned by @RelativeScheme, lowercased
     * If $result.scheme is equal to $base.scheme, then perform the
       following steps:
       * Set $result.host to $base.host
       * Replace $result.path by the <a>path concatenation</a> of 
           $base.path and $result.path
     * If $result.scheme is not equal to $base.scheme, then perform the
       following steps:
       * Remove all empty strings from the front of $result.path.
       * If the first element of $result.path does not contain an "@"
           sign, then set $result.host to this elements
           value, and remove this element from $result.path.
       * If the first element of the path does contain an "@"
           sign, then remove this element from the path and 
           perform the following steps with this value:
           * The part of this value that precedes the first "@"
               is to be treated as an @UserInfo value.  If it
               contains a ":", set $result.username to the value
               up to the position of the first ":" and set
               $result.password to the value starting with the position
               after the first ":".  If no ":" is present,
               set $result.username to this entire value.
           * Set $result.host to the value starting after the first
               "@".
       * if $result.host is either an empty string or contains a
           colon, then terminate parsing with a <a>parse error</a>.

   </ol>
*/
AbsoluteUrl
  = scheme:(RelativeScheme ':')? slash1:[/\\] slash2:[/\\]+
    userinfo:UserInfo?
    host:Host 
    port:(':' Port)?
    [/\\] ?
    remainder:RelativeUrl
  {
    result = copy(remainder, userinfo, host, port && port[1]);

    if (scheme) {
      result.scheme = scheme[0].toLowerCase()
    } else {
      result.scheme = base.scheme
    }

    host = host.split('@');
    result.host = host.pop();
    if (host.length > 0) {
      result.exception = 
        'At sign ("@") in user or password needs to be percent encoded';
      if (!userinfo) userinfo = {username: ''}
      if (userinfo.password != null) {
        userinfo.password += Array(host.length+1).join("%40")+host.join('')
      } else {
        userinfo.username += Array(host.length+1).join("%40")+host.join('')
      }
    };

    if (userinfo) {
      if (result.host == '') error('Empty host');
      result.username = userinfo.username;
      if (userinfo.password != null) result.password = userinfo.password
    };

    if (port && Url.DEFAULT_PORT[result.scheme] != port[1]) {
      result.port = port[1]
    };

    if (slash1 == '\\' || slash2.join().indexOf("\\") != -1) {
      result.exception = 'Backslash ("\\") used as a delimiter'
    } else if (slash2.length != 1) {
      result.exception = 'Extraneous slashes found'
    }

    return result
  }

  / scheme:RelativeScheme 
    ':'
    remainder:RelativeUrl
  {
    result = remainder;
    result.exception = 'Expected a slash ("/")';
    result.scheme = scheme.toLowerCase();

    if (base.scheme == result.scheme) {
      result.host = base.host;
      result.path = Url.path_concat(base.path, result.path)
    } else {
      while (result.path[0] == '') result.path.shift();

      if (result.path.length > 0) {
        var host = result.path.shift().split('@');
        if (host.length > 1) {
          var userinfo = host.shift();
          var split = userinfo.indexOf(':');
          if (split == -1) {
            result.username = userinfo
          } else {
            result.username = userinfo.slice(0,split)
            result.password = userinfo.slice(split+1)
          }
        };

        result.host = host.join('@')
      };

      if (!result.host || result.host == '') error('Empty host');
      if (result.host.indexOf(':') != -1) error('Invalid host');
    };

    return result
  }

/*
  Initialize $result to be empty object.  
  If @Path is present in the input, set $result.path to this value.
  If @Query is present in the input, set $result.query to this value.
  If @Fragment is present in the input, set $result.fragment to this value.
  Return $result.
*/
RelativeUrl
  = path:Path?
    query:('?' Query)?
    fragment:('#' Fragment)?
  {
    result = copy({path: path}, path, fragment && fragment[1]);

    if (query) {
      result.query = query[1]
    };

    if (fragment) {
      result.fragment = fragment[1].toString()
    };

    return result
  }

/*
  Initialize $result to be a JSON object with $scheme
  set to be the result returned by @Scheme, and
  $scheme_data set to the result returned by @Data.
  If @Query is present in the input, set $result.query to this value.
  If @Fragment is present in the input, set $result.fragment to this value.
  Return $result.
*/
NonRelativeUrl
  = scheme:Scheme ':'
    data:Data
    query:('?' Query)?
    fragment:('#' Fragment)?
  {
    result = copy({scheme: scheme, scheme_data: data}, data, fragment && fragment[1]);

    if (query) {
      result.query = query[1]
    };

    if (fragment) {
      result.fragment = fragment[1].toString()
    };

    return result
  }

/*
  Six relative schemes are defined.  They are to be matched against the input
  in a case insensitive manner.  Return the results as a lowercased string.
*/
RelativeScheme
  = "ftp"i
  / "gopher"i
  / "https"i
  / "http"i
  / "wss"i
  / "ws"i

/*
  Schemes consist of one or more the letters "a" through
  "z", "A" through "Z", or any of the
  following special characters: hyphen-minus (U+002D),
  plus sign (U+002B) or full stop (U+002D).
  Return the results as a lowercased string.
*/
Scheme
  = scheme:[-a-zA-Z+.]+
  {
    return scheme.join('').toLowerCase()
  }

/*
  Initialize $result to be a JSON object with $user
  set to be the result returned by @User.  If
  @Password is present in the input, set $result.password
  to this value.  Return $result.
*/
UserInfo
  = user:User password:(':' Password)? '@'
  {
    var result = copy({username: user}, user);

    if (password) {
      result['password'] = password[1];
      if (password[1].exception) result.exception = password[1].exception
    };

    return result
  }

/*
  Consume all characters until either 
  a solidus (U+002F),
  a reverse solidus (U+005C),
  a question mark (U+003F),
  a number sign (U+0023), 
  a commercial at (U+0040), 
  a colon (U+003A), 
  or the end of string is encountered.
  Return the <a title=cleanse>cleansed</a> result using the
  <a href="https://url.spec.whatwg.org/#default-encode-set">default encode
   set</a>.
*/
User
  = user:[^/\\?#@:]*
  {
    return cleanse(user, Url.DEFAULT_ENCODE_SET, 'user')
  }

/*
  Consume all characters until either 
  a solidus (U+002F),
  a reverse solidus (U+005C),
  a question mark (U+003F),
  a number sign (U+0023), 
  a commercial at (U+0040), 
  or the end of string is encountered.
  Return the <a title=cleanse>cleansed</a> result using the
  <a href="https://url.spec.whatwg.org/#default-encode-set">default encode
   set</a>.
*/
Password
  = password:[^/\\?#@]*
  {
    return cleanse(password, Url.DEFAULT_ENCODE_SET, 'password')
  }

/*
   If the input contains an @IPV6Addr, return "[" plus
   the result returned by @IPV6Addr plus "]"  Otherwise:

     * If the string starts with a left square bracket (U+005B),
       terminate parsing with a <a>parse error</a>.
     * If any U+0009, U+000A,
       U+000D, U+200B, U+2060, or U+FEFF characters are present in the input,
       remove those characters and indicate a <a>parse error</a>.
     * <a href="https://url.spec.whatwg.org/#percent-decode">Utf8 percent
       decode</a> the result.
     * Replace all Fullwidth unicode characters (in the range of
       U+FF01 to U+FF5E )with their non-fullwidth
       equivalents.
     * If the result contains any character in the range of
       U+FDD0 to U+FDEF, terminate paring with a <a>parse error</a>.
     * If the result contains any of the following, terminate parsing with a
       <a>parse error</a>:
       number sign (U+023),
       percent (U+025),
       solidus (U+02F),
       reverse solidus (U+05C),
       colon (U+03A),
       question mark (U+03F),
       left square bracket (U+05B),
       right square bracket (U+05B),
       null (U+0000),
       tab (U+0009),
       line feed (U+000A),
       carriage return (U+000D),
       space (U+0020),
       no-break space (U+00A0),
       ogham space mark (U+1680),
       en quad (U+2000),
       zero width space (U+200B),
       narrow no-break space (U+202F),
       medium mathematical space (U+205F), or
       ideographic space (U+3000), 
     * IDNA encode the result as follows:
        * split the string whenever any of the following are encountered:
            U+002E (full stop), U+3002 (ideographic
            full stop), U+FF0E (fullwidth full stop),
            U+FF61 (halfwidth ideographic full stop)
        * If any of the pieces contains any character outside of the range of
            U+0020 to U+007E, replace that piece with
            the string "xn--" concatenated with the punycode
            [[!RFC3492]] encoded value of the result.
        * If any of the pieces, other than the first one, are empty strings,
            indicate a <a>parse error</a>.
        * Rejoin the pieces using U+002E (full stop) as the
            separator.

   Note: this description above needs to be reconciled with, and defer to,
   the <a href="https://encoding.spec.whatwg.org/">Encoding
   Living Standard</a>.  For example, full Unicode normalization is more than
   simply converting full-width characters to their normal width equivalents.
*/
Host
  = '[' addr:IPV6Addr ']'
  {
    return '[' + addr + ']'
  }

  / host:[^:/\\?#]*
  {
    var warn = null;

    if (host[0] == '[') error("Invalid IPV6 address");

    for (var i=0; i<host.length; i++) {
      if (/^[\u0009\u000A\u000D]$/.test(host[i])) {
        host.splice(i--, 1);
        warn = "Tab, new line, or cariage return found in host"
      } else if (/^[\u200B\u2060\uFEFF]$/.test(host[i])) {
        host.splice(i--, 1); // TODO: verify
      }
    }

    host = host.join('').toLowerCase();
    if (/%/.test(host)) host = Url.utf8_percent_decode(host)

    for (var i=0; i<host.length; i++) {
      var c = host.charAt(i);

      if (/^[\uFF01-\uFF5E]$/.test(c)) {
        c = String.fromCharCode(c.charCodeAt(0)-0xFF00+0x20);
        host = host.slice(0, i) + c + host.slice(i + 1)
      }

      if (/^[\uFDD0-\uFDEF]$/.test(c)) {
        error('Invalid domain character') // TODO: verify
      } else if (/[\u0000\u0009\u000A\u000D\u0020#%\/:?\[\\\]]/.test(c)) {
        error('Invalid domain character')
      } else if (/[\u00A0\u1680\u2000-\u200B\u202F\u205F\u3000]/.test(c)) {
        error('Invalid domain character')
      }
    };

    host = host.split(/[\u002E\u3002\uFF0E\uFF61]/);
    for (var i=0; i<host.length; i++) {
      if (!/^[\x20-\x7e]*$/.test(host[i])) {
        host[i] = 'xn--' + punycode.encode(host[i])
      } else if (host[i] == '' && i != 0) {
        // Not defined here:
        //   https://url.spec.whatwg.org/#host-state
        // And the following only defines hard errors (e.g. step 5);
        //   https://url.spec.whatwg.org/#concept-host-parser
        // First implemented by galimatias 
        warn = new extension_exception("DNS violation: Host contains empty label")
      }
    };

    host = new String(host.join('.'));
    if (warn) host.exception = warn;
    return host
  }

/*
  In addition to parsing a series of zero or more H16 values separated by a
   colon, optionally followed by a double colon and a series of zero or more
   H16 values, optionally followed by a colon and a LS32 value; there are
   further restrictions on the number of H16 values that can be present
   in each series, as documented in 
   <a href="https://www.iana.org/assignments/svrloc-templates/iscsi_target.1.0.en">ipv6-number</a>
   production rule.  Return the result as a string.

   Note: the further restrictions need to be enumerated and inlined.
*/
IPV6Addr
  = addr:(((H16 ':')* ':')? (H16 ':')* (H16 / LS32))
  {
    var result = '';

    if (addr[0]) {
      for (var i=0; i<addr[0][0].length; i++) {
        result += addr[0][0][i][0] + ':'
      };
      result += ':'
    };

    for (var i=0; i<addr[1].length; i++) {
      result += addr[1][i] + ':'
    };

    result += addr[2];

    return result
  }

/*
  Return up to four hexadecimal characters as a string.
*/
H16
  = a:[0-9A-Fa-f] b:[0-9A-Fa-f]? c:[0-9A-Fa-f]? d:[0-9A-Fa-f]?
  {
    return a + (b ? b : '') + (c ? c : '') + (d ? d : '')
  }

/*
  Return four decimal bytes separated by full stop characters as a string.
*/
LS32
  = a:DECIMAL_BYTE '.' b:DECIMAL_BYTE '.' d:DECIMAL_BYTE '.' d:DECIMAL_BYTE
  {
    return a.join('') + b.join('') + c.join('') + d.join('')
  }

/*
  Decimal bytes are a string of up to three decimal digits.  If the results
  converted to an integer are greater than 255, terminate processing with
  a <a>parse error</a>.
*/
DECIMAL_BYTE
  = a:[0-2]? b:[0-9]? c:[0-9]
  {
    return (a ? a : '') + (b ? b : '') + c
  }

/*
  Consume all characters until either 
  a solidus (U+002F),
  a reverse solidus (U+005C),
  a question mark (U+003F),
  or the end of string is encountered.
  If any U+0009, U+000A, U+000D, U+200B, U+2060, or U+FEFF characters are
  present in the result, remove those characters and indicate a
  <a>parse error</a>.
  Remove leading U+0030 code points from result
  until either the leading code point is not U+0030 or result is
  one code point. 
  If any characters that remain are not decimal digits, terminate processing
  with a <a>parse error</a>.
  Otherwise, return the result as a string.
*/
Port
  = port:[^/\\?#]*
  {
    var warn = null;

    for (var i=0; i<port.length; i++) {
      if (/^[\u0009\u000A\u000D]$/.test(port[i])) {
        port.splice(i--, 1);
        warn = "Tab, new line, or cariage return found in port";
      }
    }

    port = port.join('').replace(/^0+(\d)/, '$1');
    if (!/^\d*$/.test(port)) error('Invalid port number');

    if (warn) {
      port = new String(port);
      port.exception = warn
    };

    return port
  }

/*
  If any of the path separators are a reverse solidus ("\"), indicate
  a <a>parse error</a>.

  Extract all the pathnames into an array.  Process each name as follows:

    * If any U+0009, U+000A, U+000D, U+200B, U+2060, or U+FEFF characters are
      present in the name, remove those characters and indicate a <a>parse
      error</a>.
    * If the name includes a percent sign (U+0025) that is not immediately
      followed by two hexadecimal characters, indicate a <a>parse error</a>.
    * If the name includes a character is not a <a href="https://url.spec.whatwg.org/#url-code-points">URL code point</a> or a percent sign ("%"), indicate a parse error.
    * <a href="https://url.spec.whatwg.org/#percent-encode">Percent encode</a>
      the result using the
      <a href="https://url.spec.whatwg.org/#default-encode-set">Default encode
      set</a>.
    * If the name is "." or "%2e" (case insensitive),
      then process this name based on the position in the array:
        * If the position is other than the last, remove the name from the list.
        * If the array is of length 1, replace the entry with an empty string.
        * Otherwise, leave the entry as is.
    * If the name is "..", ".%2e", "%2e.",
      or "%2e%2e" (all to be compared in a case insensitive manner),
      then process this name based on the position in the array:
        * If the position is the first, then remove it.
        * If the position is other than the last, then remove it and the
            one before it.
        * If the position is the last, then remove it and the one before it,
            then append an empty string.

  Return the array.
*/
Path
  = path:([^/\\?#]* [/\\])* basename:[^/\\?#]*
  {
    var warn = null;

    path.push([basename]);

    for (var i=0; i<path.length; i++) {
      var name = path[i][0];

      for (var j=0; j<name.length; j++) {
        if (/^[\u0009\u000A\u000D]$/.test(name[j])) {
          warn = "Tab, new line, or cariage return found in path";
          name.splice(j--, 1)
        }
      };

      if (name.some(function(c) {
        return c != '%' && !Url.URL_CODE_POINTS.test(c)
      })) {
        warn = "Illegal character in path";
      };

      name = name.join('');

      if (/%($|[^0-9a-fA-F]|.$|.[^0-9a-fA-F])/.test(name)) {
        warn = 'Percent sign ("%") not followed by two hexadecimal digits'
      } else if (path[i][1] == "\\") {
        warn = 'Backslash ("\\") used as path segment delimiter'
      };

      path[i] = Url.percent_encode(name, Url.DEFAULT_ENCODE_SET)

      if (/^(\.|%2e)$/i.test(path[i])) {
        if (i < path.length-1) {
          path.splice(i--, 1)
        } else if (i != 0) {
          path[i] = ''
        }
      } else if (/^(\.|%2e)(\.|%2e)$/i.test(path[i])) {
        if (i == 0) {
          path.splice(i--, 1)
        } else if (i < path.length-1) {
          --i;
          path.splice(i--, 2)
        } else {
          path.splice(--i, 2, '')
        }
      }
    };

    if (warn) {
      path.exception = warn
    };

    return path
  }

/*
  Consume all characters until either a question mark (U+003F), a
  number sign (U+0023), or the end of string is encountered.
  If any U+0009, U+000A, U+000D, U+200B, U+2060, or U+FEFF characters are
  present in the result, remove those characters and indicate a
  <a>parse error</a>.
  If any character in the result is not a
  <a href="https://url.spec.whatwg.org/#url-code-points">URL code point</a> or
  a percent sign ("%"), indicate a parse error.
  Return the result as a string.
*/
Data
  = data:[^?#]*
  {
    var warn = null;

    for (var i=0; i<data.length; i++) {
      if (/^[\u0009\u000A\u000D]$/.test(data[i])) {
        warn = "Tab, new line, or cariage return found in scheme data"
        data.splice(i--, 1)
      }
    }

    if (data.some(function(c) {
      return c != '%' && !Url.URL_CODE_POINTS.test(c)
    })) {
      warn = "Illegal character in scheme data";
    };

    data = new String(data.join(''));
    if (warn) data.exception = warn;
    return data
  }

/*
  Consume all characters until either a 
  number sign (U+0023) or the end of string is encountered.
  <a href="https://url.spec.whatwg.org/#percent-encode">Percent encode</a>
  the result using the Query encode set.  Return the result as a string.

  Note: Query encode set is defined to be bytes that are less than 0x21,
  greater than 0x7E, or one of 0x22, 0x23, 0x3C, 0x3E, and 0x60.

  Note: encoding override logic needs to be added.
*/
Query 
  = query:[^#]*
  {
    return Url.percent_encode(query.join(''), Url.QUERY_ENCODE_SET)
  }

/*
  Consume all remaining characters in the input.  
  Return the <a title=cleanse>cleansed</a> result using the
  <a href="https://url.spec.whatwg.org/#default-encode-set">simple encode
   set</a>.
*/
Fragment 
  = fragment:.*
  {
    return cleanse(fragment, Url.SIMPLE_ENCODE_SET, 'fragment')
  }

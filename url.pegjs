// This file contains JavaScript code inside { curly braces }.
// This file contains Bikeshed markup inside /* comments */.
// This file contains PEG.js grammar rules which are converted to
//   railroad diagrams in the spec and executable JavaScript.

{
  var base = options.base || {scheme: 'about'};
  var url = options.url;
  var encodingOverride = options.encodingOverride || 'utf-8';

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
  function extensionException(value) {
    this.value = value || '';
    this.length = this.value.length;
    this.extension = true;
  };
  extensionException.prototype = new String;
  extensionException.prototype.toString = 
    extensionException.prototype.valueOf = function() {return this.value}

  /* cleanse a url component given a encode set */
  function cleanse(string, encodeSet, component) {
    warn = null;

    for (var i=0; i<string.length; i++) {
      if (/^[\u0009\u000A\u000D]$/.test(string[i])) {
        warn = "Tab, new line, or carriage return found in " + component
        string.splice(i--, 1)
      }
    }

    if (string.some(function(c) {
      return c != '%' && !Url.URL_CODE_POINTS.test(c)
    })) {
      warn = "Illegal character in " + component
    };

    string = string.join('');

    if (/%($|[^0-9a-fA-F]|.$|.[^0-9a-fA-F])/.test(string)) {
      warn = 'Percent sign ("%") not followed by two hexadecimal digits in ' +
       component
    }

    if (encodeSet) string = Url.percentEncode(string, encodeSet);

    if (warn) {
      string = new String(string);
      string.exception = warn;
    };

    return string
  }

  /* Regular expression "lookahead" on the input string */
  function lookahead(expected) {
    return expected.test(input.slice(offset()))
  }
}

/*
   returns: { 
     <a href="#concept-url-scheme">scheme</a>,
     <a href="#concept-url-scheme-data">scheme-data</a>,
     <a href="#concept-url-username">username</a>,
     <a href="#concept-url-password">password</a>,
     <a href="#concept-url-host">host</a>,
     <a href="#concept-url-port">port</a>,
     <a href="#concept-url-path">path</a>,
     <a href="#concept-url-query">query</a>,
     <a href="#concept-url-fragment">fragment</a>
   }

   <ol>
   <li><a>Parse $input</a> according to the above railroad diagram.
   <li>Let $result be the <a>value of</a> @FileUrl, @NonRelativeUrl,
       or @RelativeUrl depending on which <a>is present</a>.
   <li>If @Query <a>is present</a>, set $result.query to the <a>value of</a>
       @Query.
   <li>If @Fragment <a>is present</a>, set $result.fragment to the 
       <a>value of</a> @Fragment.
   <li>If $result.scheme has a <a>default port</a>, and if $result.port is
       equal to that default, then delete the $port property from $result.
   <li>Return $result.
   </ol>
*/
Url
  = base:(FileUrl / NonRelativeUrl / RelativeUrl)
    query:('?' Query)?
    fragment:('#' Fragment)?
{
    var result = copy(base, query && query[1], fragment && fragment[1]);

    if (query) {
      result.query = query[1]
    };

    if (fragment) {
      result.fragment = fragment[1].toString()
    };

    if (Url.DEFAULT_PORT[result.scheme] == result.port) {
      delete result.port;
    }

    return result
}

/*
   returns: { 
     <a href="#concept-url-scheme">scheme</a>,
     <a href="#concept-url-host">host</a>,
     <a href="#concept-url-path">path</a>
   }

  <em>"<code>file</code>" is to be matched case insensitively.</em>

   <ol>
   <li><a>Parse $input</a> according to the above railroad diagram.
   <li>Let $result be an empty object.

   <li>Three rows of production rules are defined for files, numbered from top
   to bottom.  Examples and evaluation instructions for each:

   <ol>
   <li><div class=example><code>file:c:\foo\bar.html</code></div>

     <ol>
     <li>Set $result.scheme to "file".
     <li>Set $result.path to the <a>value of</a> @Path.
     <li>Remove the first element from $result.path if it is an empty
       string and if there is a second element which has a non-empty value.
     <li>Construct a string using the <a>ASCII alpha</a>
       following the first ":" in the input
       concatenated with a ":".  Prepend this string to 
       $result.path.
     </ol>

   <li><div class=example><code>/C|\foo\bar</code></div>

     <ol>
     <li>Set $result.scheme to "file".
     <li>If the @Host <a>is present</a>, set $result.host
       to the <a>value of</a> @Host.
     <li>If the @Host <a title='is present'>is not present</a> and no slashes
       precede the @Path in the input, then prepend $base.path
       minus the last element to the $result.path.
     <li>Set $result.path to the <a>value of</a> @Path.
     </ol>

   <li><div class=example><code>file:/example.com/</code></div>

     <ol>
     <li>Indicate a <a>conformance error</a>.
     <li>Set $result.scheme to "file".
     <li>Set $result.path to the <a>value of</a> @Path.
     <li>Remove the first element from $result.path if it is an empty
       string and if there is a second element which has a non-empty value.
     <li>Construct a string consisting of the code point following
       the initial "/" (if any) in the production rule concatenated
       with a ":".  Prepend this string to the $result.path array.
     </ol>

   </ol>

  <li>Return $result.
  </ol>

  <p class=XXX>At the present time, file URLs are generally not
  interoperable, and therefore are effectively implementation defined.
  Furthermore, the parsing rules in this section have not enjoyed wide review,
  and therefore are more likely to be subject to change than other parts of this
  specification.  
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=27518">bug 27518</a>
  proposes to remove all normative definitions for file URLs that are not
  known to be interoperable.  
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=23550">Bug 23550</a>  
  and
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=23717">bug 23717</a>
  suggest less drastic changes.  
*/
FileUrl
  = 'file'i ':' 
    drive:[a-zA-Z] [:|]
    [\\/]? path:Path
  {
    var result = copy({path: path}, path);
    result.scheme = 'file';
    if (result.path[0] == '' && result.path[1] != '') result.path.shift();
    result.path.unshift(drive+':');
    return result
  }

  / '/'*
    drive:[a-zA-Z] '|'
    '/'? path:Path
  {
    var result = copy({path: path}, path);
    result.exception = 'Legacy compatibility issue';
    result.scheme = 'file';
    if (result.path[0] == '' && result.path[1] != '') result.path.shift();
    result.path.unshift(drive+':');
    return result
  }

  / 'file'i ':' host:('/' '/' Host)? slash:'/'* path:Path
  {
    var result = copy({path: path}, path);
    if (host) {
      result.host = host[2];
    } else if (slash.length == 0) {
      var path = base.path.slice(0, -1);
      path.push.apply(path, result.path);
      result.path = path
    }
    result.scheme = 'file';
    return result
  }

/*
   returns: { 
     <a href="#concept-url-scheme">scheme</a>,
     <a href="#concept-url-scheme-data">scheme-data</a>
   }

  <div class=example><code>javascript:alert("Hello, world!");</code></div>

  <ol>
  <li><a>Parse $input</a> according to the above railroad diagram.
  <li>If the <a>value of</a> @Scheme does not
  match any <a>relative scheme</a> then return failure.

  <li>Set <code>encoding override</code> to "utf-8".

  <li>Initialize $result to be a JSON object with $scheme
  set to be the result returned by @Scheme, and
  $schemeData set to the <a>value of</a> @SchemeData.
  <li>Return $result.
  </ol>

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=26338">bug 26338</a>
  may change how encoding override is handled.

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=27233">bug 27233</a>
  may add support for relative URLs for unknown schemes.
*/
NonRelativeUrl
  = scheme:Scheme ':'
    &{ return Url.RELATIVE_SCHEME.indexOf(scheme) == -1 }
    data:SchemeData
  {
    encodingOverride = 'utf-8';

    return copy({scheme: scheme, scheme_data: data}, data);
  }

/*
   returns: { 
     <a href="#concept-url-scheme">scheme</a>,
     <a href="#concept-url-username">username</a>,
     <a href="#concept-url-password">password</a>,
     <a href="#concept-url-host">host</a>,
     <a href="#concept-url-port">port</a>,
     <a href="#concept-url-path">path</a>
   }

   <ol>
   <li><a>Parse $input</a> according to the above railroad diagram.

   <li>Four rows of production rules are defined for relative URLs, numbered
   from top to bottom.  Examples and evaluation instructions for each:

   <ol>
   <li><div class=example><code>http://user:pass@example.org:21/foo/bar</code></div>

     <ol>
     <li>If anything other than two forward solidus code points ("//")
     immediately follows the first colon in the input, indicate a
     <a>conformance error</a>.

     <li>Let $result be the <a>value of</a> @Authority.

     <li>If @NonFileRelativeScheme <a>is present</a> in the input, then
     set $result.scheme to the <a>value of</a> @NonFileRelativeScheme.

     <li>If @NonFileRelativeScheme <a title='is present'>is not present</a>,
     then set $result.scheme to the value of $base.scheme.

     <li>If @Path <a>is present</a>, set $result.path to the <a>value of</a>
     @Path.
     </ol>

   <li><div class=example><code>ftp:/example.com/</code> parsed using a base of
    <code>http://example.org/foo/bar</code></div>

    <ol>

    <li>If the <a>value of</a> @Scheme equals $base.scheme then return failure.

    <li>Indicate a <a>conformance error</a>.

    <li>Let $result be the <a>value of</a> @Authority.

    <li>Set $result.scheme to the <a>value of</a> @NonFileRelativeScheme.

    <li>If $result.host is either an empty string or contains a
    colon (U+003A), then terminate parsing with a <a>parse exception</a>.

    <li>If @Path <a>is present</a>, set $result.path to the <a>value of</a>
    @Path.
    </ol>

   <li><div class=example><code>http:foo/bar</code></div>

    <ol>
    <li>Indicate a <a>conformance error</a>.

    <li>Let $result be an empty object.

     <li>Set $result.scheme to the <a>value of</a> @NonFileRelativeScheme.
     <li>Set $result.scheme to the <a>value of</a> @Scheme.
     <li>Set $result.host to $base.host.
     <li>Set $result.path by the <a>path concatenation</a> of 
         $base.path and @Path.
     </ol>

   <li><div class=example><code>/foo/bar</code></div>

    <ol>
    <li>Let $result be an empty object.
    <li>Set $result.scheme to $base.scheme.
    <li>Set $result.host to $base.host.
    <li>if the length of @Path is greater than zero, and the first segment
      in @Path contains a colon (U+003A), indicate a <a>conformance error</a>.
    <li>Replace $result.path with the <a>path concatenation</a> of $base.path
    and @Path.
    </ol>

   </ol>

   <li>Return $result.
  </ol>
*/
RelativeUrl
  = scheme:(NonFileRelativeScheme ':')? slash1:[/\\] slash2:[/\\]
    authority:Authority
    path:([/\\] Path)?
  {
    result = copy(authority, path && path[1]);
    if (path) result.path = path[1];

    if (scheme) {
      result.scheme = scheme[0];
    } else {
      result.scheme = base.scheme;
    }

    if (slash1 == '\\' || slash2 == '\\') {
      result.exception = 'Backslash ("\\") used as a delimiter'
    } else if (path && path[0] == '\\') {
      result.exception = 'Backslash ("\\") used as a delimiter'
    }

    return result
  }

  / scheme:NonFileRelativeScheme 
    &{ return base.scheme != scheme }
    ':'
    slash1:[\\/]?
    authority:Authority
    path:([/\\] Path)?
  {
    result = copy(authority, path && path[1]);
    if (path) result.path = path[1];
    result.exception = 'Expected a slash ("/")';
    result.scheme = scheme.toLowerCase();

    if (!result.host || result.host == '') error('Empty host');
    if (result.host.indexOf(':') != -1) error('Invalid host');

    if (slash1 == '\\') {
      result.exception = 'Backslash ("\\") used as a delimiter'
    } else if (path && path[0] == '\\') {
      result.exception = 'Backslash ("\\") used as a delimiter'
    }

    return result
  }

  / scheme:NonFileRelativeScheme 
    ':'
    path:Path
  {
    var result = copy({path: path}, path);
    result.exception = 'Expected a slash ("/")';
    result.scheme = scheme;

    result.host = base.host;
    result.path = Url.pathConcat(base.path, result.path)

    return result
  }

  / path:Path
  {
    if (Url.RELATIVE_SCHEME.indexOf(base.scheme) == -1) {
      error("relative URL provided with a non-relative base")
    };

    var result = copy({path: path}, path);
    result.scheme = base.scheme;
    result.host = base.host; 

    if (result.path.length > 0 && result.path[0].indexOf(':') != -1) {
      result.exception = 'leading segment in a relative path contains a colon';
    }

    result.path = Url.pathConcat(base.path, result.path)

    return result
  }

/*
  returns: String

  <em>Schemes are to be matched against the input in a case insensitive
  manner.</em>

  <ol>
  <li><a>Parse $input</a> according to the above railroad diagram.
  <li>Set <code>encoding override</code> to "utf-8" if the scheme matches
  "wss" or "ws".

  <li>Return the scheme as a lowercased string.
  </ol>

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=26338">bug 26338</a>
  may change how encoding override is handled.
*/
NonFileRelativeScheme
  = "ftp"i
  / "gopher"i
  / "https"i
  / "http"i
  / rs:"wss"i
{
  encodingOverride = 'utf-8';
  return rs
}
  / rs:"ws"i
{
  encodingOverride = 'utf-8';
  return rs
}

/*
  returns: String

  A scheme consists of an <a>ASCII alpha</a>,
  followed by zero or more <a>ASCII alpha</a> or any of the following
  code points: hyphen-minus (U+002D), plus sign (U+002B) or full stop
  (U+002E).
  Return the results as a lowercased string.
*/
Scheme
  = scheme:([a-zA-Z] [-a-zA-Z+.]*)
  {
    return (scheme[0] + scheme[1].join('')).toLowerCase()
  }

/*
   returns: { 
     <a href="#concept-url-username">username</a>,
     <a href="#concept-url-password">password</a>,
     <a href="#concept-url-host">host</a>,
     <a href="#concept-url-port">port</a>
   }

   <ol>
   <li><a>Parse $input</a> according to the above railroad diagram.
   <li>Let $result be an empty object.
   <li>If @User <a>is present</a>, set $result.username to the <a>value of</a>
       @User.
   <li>If @Password <a>is present</a>, set $result.password to the
       <a>value of</a> @Password.
   <li>Set $result.host to the <a>value of</a> @Host up to the first "@" sign,
       if any.  If no "@" signs are present in the <a>value of</a> @Host, then
       set $result.host to the <a>value of</a> @Host.
   <li>If one or more "@" signs are present in the <a>value of</a> @Host,
       then perform the following steps:
       <ol>
       <li>Indicate a <a>conformance error</a>.
       <li>Initialize $info to the value of "%40" plus the remainder of the
           @Host after the first "@" sign.  Replace all remaining "@" signs in
           $info, with the string "%40".
       <li>If @Password <a>is present</a>, append $info to $result.password.
       <li>If @Password <a title="is present">is not present</a> and @User
           <a>is present</a>, append $info to $result.username.
       <li>If @User <a title="is present">is not present</a>, set
           $result.username to $info.
       </ol>
   <li>If @Port <a>is present</a>, set $result.port to its value.
   <li>Return $result.
   </ol>
*/
Authority
  = userpass:( User (':' Password)? '@' )?
    host:Host 
    port:(':' Port)?
  {
    result = copy({}, host, userpass && userpass[0],
      userpass && userpass[1] && userpass[1][1], port && port[1]);

    if (userpass) {
      result.username = userpass[0];
      if (userpass[1]) result.password = userpass[1][1];
    }

    host = host.split('@');
    result.host = host.pop();
  
    if (host.length > 0) {
      result.exception = 
        'At sign ("@") in user or password needs to be percent encoded';
      var info = '%40' + host.join('%40');
      if (result.password != null) {
        result.password += info
      } else {
        result.username += info
      }
    };

    if (result.username != null && result.host == '') {
      error('Empty host');
    };

    if (port) result.port = port[1];

    return result;
  }

/*
  returns: String

  Consume all code points until either
  a solidus (U+002F),
  a reverse solidus (U+005C),
  a question mark (U+003F),
  a number sign (U+0023), 
  a commercial at (U+0040), 
  a colon (U+003A), 
  or the end of string is encountered.
  Return the <a title=cleanse>cleansed</a> result using the
  <a>default encode set</a>.
*/
User
  = user:[^/\\?#@:]*
  {
    return cleanse(user, Url.DEFAULT_ENCODE_SET, 'user')
  }

/*
  returns: String

  Consume all code points until either
  a solidus (U+002F),
  a reverse solidus (U+005C),
  a question mark (U+003F),
  a number sign (U+0023), 
  a commercial at (U+0040), 
  or the end of string is encountered.
  Return the <a title=cleanse>cleansed</a> result using the
  <a>default encode set</a>.
*/
Password
  = password:[^/\\?#@]*
  {
    return cleanse(password, Url.DEFAULT_ENCODE_SET, 'password')
  }

/*
   returns: String

   <ol>
   <li><a>Parse $input</a> according to the above railroad diagram.
   <li>If @IPv6Addr <a>is present</a>, return the <a>value of</a> @IPv6Addr.
   <li>If @IPv4Addr <a>is present</a>, return the <a>value of</a> @IPv4Addr.
   <li>Let $result be the characters matched by the railroad diagram.
   <li>If any U+0009, U+000A, U+000D, U+200B, U+2060, or U+FEFF code points are
       present in $result, remove those code points and indicate a
       <a>conformance error</a>.
   <li>Let $domain be the result of
       <a href=#concept-host-parser>host parsing</a> $result.  If this results
       in a failure, terminate processing with a <a>parse exception</a>.  If <a
       href=#concept-host-parser>host parsing</a> returned a value that was
       different than what was provided as input, indicate a <a>conformance
       error</a>.
   <li>Try parsing $domain as an @IPv4Addr. If this succeeds, replace $domain
       with the result.
   <li>Validate $domain as follows:
        <ol>
        <li>split the string at U+002E (full stop) code points
        <li>If any of the pieces, other than the first one, are empty strings,
            indicate a <a>conformance error</a>.
	</ol>
   <li>Return $domain.
   </ol>

   <p class=XXX>The resolution of
   <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=25334">bug 25334</a>
   may change what codepoints are allowed in a domain.

   <p class=XXX>The resolution of
   <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=27266">bug 27266</a>
   may change the way domain names and trailing dots are handled.
*/
Host
  = addr:IPv6Addr
    &{ return lookahead(/^([\\\/?#:]|$)/) }
  {
    return addr
  }

  / addr:IPv4Addr
    &{ return lookahead(/^([\\\/?#:]|$)/) }
  {
    return addr
  }

  / host:[^:/\\?#]*
  {
    var warn = null;

    for (var i=0; i<host.length; i++) {
      if (/^[\u0009\u000A\u000D]$/.test(host[i])) {
        host.splice(i--, 1);
        warn = "Tab, new line, or carriage return found in host"
      }
    }

    host = Url.utf8PercentDecode(host.join(''));
    var before = host;
    host = IDNA.processing_map(host, false, true);

    /* warn if IDNA processing changed the URL */
    if (host != before) {
      before = before.split('');
      warn = "Domain name contains an IDNA ignored character";
      host.split('').forEach(function(c) {
        var index = before.indexOf(c);
        if (index > -1) {
          before.splice(index, 1);
        } else {
          warn = "Domain name contains an IDNA mapped character";
        }
      });
    }

    /* If the result can be parsed as an IPv4 address, return that instead */
    try {
      return UrlParser.parse(host, {startRule: 'IPv4Addr'});
    } catch (e) {
    }

    /* warn if NFC normalization changed the URL */
    before = host;
    host = host.normalize('NFC');
    if (host != before) {
      warn = "Domain name contains an non-NFC normalized character";
    }

    if (/[\u0000\u0009\u000A\u000D\u0020#%\/:?\[\\\]]/.test(host)) {
      var c = host.match(/[\u0000\u0009\u000A\u000D\u0020#%\/:?\[\\\]]/)[0];
      error('Invalid domain character U+' +
        ("000" + c.charCodeAt(0).toString(16)).slice(-4).toUpperCase());
    }

    host = host.split('.');
    for (var i=0; i<host.length; i++) {
      if (!/^[\x20-\x7e]*$/.test(host[i])) {
        host[i] = 'xn--' + punycode.encode(host[i])
      } else if (host[i] == '' && i != 0) {
        // Not defined here:
        //   https://url.spec.whatwg.org/#host-state
        // And the following only defines hard errors (e.g. step 5);
        //   https://url.spec.whatwg.org/#concept-host-parser
        // First implemented by galimatias 
        warn = new extensionException("DNS violation: Host contains empty label")
      }
    };

    host = new String(host.join('.'));
    if (warn) host.exception = warn;
    return host
  }

/*
  returns: String

  <ol>
  <li>Let $pre be the set of @H16 values before the double colon, if present.
  <li>Let $post be the remaining @H16 value before the last value
  <li>Let $last be the trailing @H16 or @LS32 value.
   
  <li>If there are no consecutive colon code points in the input string,
      indicate a <a>parse exception</a> and terminate processing unless there
      are exactly six @H16 values and one @LS32 value.
  <li>If there are consecutive colon code points present in the input,
      indicate a <a>parse exception</a> and terminate processing if the total
      number of values (@H16 or @LS32) is more than six.
  <li>Unless there is a @LS32 value present, indicate a <a>parse exception</a>
      and terminate processing if consecutive colon code points are present in
      the input or if there are more than one @LS32 value after the
      consecutive colons.

   <li>Append "0" values to $pre while the sum of the lengths of the $pre and
       $post arrays is less than six.
   <li>Append a "0" value to $pre if no @LS32 item is present in the input and
       the sum of the lengths of the $pre and $post array is seven.
   <li>Append $last to $pre.

   <li>Return '[' plus the <a href=#concept-ipv6-serializer>ipv6
   serialized</a> value of $pre as a string, plus ']'.
   </ol>

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=27234">bug 27234</a>
  may add support for link-local addresses.
*/
IPv6Addr
  = '[' addr:(((H16 ':')* ':')? (H16 ':')* (H16 / LS32)) ']'
  {
    var pre = [];
    var post = [];
    var ipv4 =  null;

    if (addr[0]) {
      for (var i=0; i<addr[0][0].length; i++) {
        pre.push(addr[0][0][i][0])
      };

      if (addr[0][0].length + addr[1].length + 1 > 6) {
        error('malformed IPv6 Address')
      }
    } else {
      if (addr[1].length != 6 || addr[2].indexOf('.')==-1) {
        error('malformed IPv6 Address')
      }
    };

    for (var i=0; i<addr[1].length; i++) {
      post.push(addr[1][i] + ':')
    };

    if (addr[2].indexOf('.') == -1 && addr[1].length > 1) {
      error('malformed IPv6 Address')
    };

    if (addr[2].indexOf('.') == -1) {
      post.push(addr[2]) 
    } else {
      ipv4 = addr[2]
    };

    return '[' + Url.canonicalizeIpv6(pre, post, ipv4) + ']'
  }

/*
  returns: String

  <ol>
  <li>If any but the last @Number is greater or equal to 256, terminate
  processing with a <a>parse exception</a>.

  <li>If the last @Number is greater than or equal to 256 to the power of (5
  minus the number of @Number's present in the input), terminate processing
  with a <a>parse exception</a>.

  <li>Unless four @Number's <a title='is present'>are present</a>, indicate a
  <a>conformance error</a>.

  <li>Let $n be the last @Number.

  <li>If the first @Number <a>is present</a>, add its 
  <a title='value of'>value</a> times 256<sup>3</sup> to $n.

  <li>If the second @Number <a>is present</a>, add its 
  <a title='value of'>value</a> times 256<sup>2</sup> to $n.

  <li>If the third @Number <a>is present</a>, add its <a title='value
  of'>value</a> times 256 to $n.

  <li>Let $result be an empty array.

  <li>Four times do the following:
    <ol>
    <li>Prepend the value of $n modulo 256 to $result.
    <li>Set $n to the value of the integer quotient of $n divided by 256.
    </ol>

  <li>Join the values in $result with a Full Stop (U+002E) code point, and
  return the results as a string.
  </ol>

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=26431">bug 26431</a>
  may change this definition.
*/
IPv4Addr
  = addr:((Number '.' (Number '.' (Number '.')?)?)? Number)
{
  var n = addr[1];
  var warn = addr[1].exception;

  if (addr[0]) {
    if (addr[0][0] >= 256) error('IPv4 address component out of range');
    if (addr[0][0].exception) warn = addr[0][0].exception;
    n += addr[0][0]*256*256*256;
    if (addr[0][2]) {
      if (addr[0][2][0] >= 256) error('IPv4 address component out of range');
      if (addr[0][2][0].exception) warn = addr[0][2][0].exception;
      n += addr[0][2][0]*256*256;
      if (addr[0][2][2]) {
        if (addr[0][2][2][0] >= 256) error('IPv4 address component out of range');
        if (addr[0][2][2][0].exception) warn = addr[0][2][2][0].exception;
        n += addr[0][2][2][0]*256;
        if (addr[1] >= 256) error('IPv4 address component out of range');
      } else {
        if (addr[1] >= 256*256) error('IPv4 address component out of range');
        warn = 'Missing IPv4 component';
      }
    } else {
      if (addr[1] >= 256*256*256) error('IPv4 address component out of range');
      warn = 'Missing IPv4 component';
    }
  } else {
    if (addr[1] >= 256*256*256*256) error('IPv4 address component out of range');
    warn = 'Missing IPv4 component';
  }

  addr = []
  for (var i=0; i<4; i++) {
    addr.unshift(n % 256); n = Math.floor(n/256)
  };
  addr = addr.join('.')

  if (warn) {
    addr = new String(addr);
    addr.exception = warn;
  }

  return addr;
}

/*
  returns: Integer

   Three production rules, with uppercase and lowercase variants, are
   defined for numbers.
   Parse the values as hexadecimal, octal, and decimal integers respectively.
   Indicate a <a>conformance error</a> if the value is hexadecimal or octal.
   Return the result as an integer.
*/
Number
  = '0' ('x' / 'X') digits:[0-9a-fA-F]+
{
  var result = parseInt(digits.join(''), 16);
  result.exception = 'Hexadecimal IPV4 component';
  return result
}

 / '0' digits:[0-7]+
{
  var result = new Number(parseInt(digits.join(''), 8));
  result.exception = 'Octal IPV4 component';
  return result
}

 / digits:[0-9]+
{
  return new Number(parseInt(digits.join('')))
}

/*
  returns: String

  Return up to four <a>ASCII hex digits</a> as a string.
*/
H16
  = a:[0-9A-Fa-f] b:[0-9A-Fa-f]? c:[0-9A-Fa-f]? d:[0-9A-Fa-f]?
  {
    return a + (b ? b : '') + (c ? c : '') + (d ? d : '')
  }

/*
  returns: String

  Return four decimal <a title='IPv4 piece'>8-bit pieces</a> separated by full
  stop (U+002E) code points as a string.
*/
LS32
  = a:DecimalByte '.' b:DecimalByte '.' d:DecimalByte '.' d:DecimalByte
  {
    return a.join('') + '.' + b.join('') + '.' + c.join('') + '.' + d.join('')
  }

/*
  returns: String

  Decimal bytes are a string of up to three decimal digits.  If the results
  converted to an integer are greater than 255, terminate processing with
  a <a>parse exception</a>.
*/
DecimalByte
  = a:[0-2]? b:[0-9]? c:[0-9]
  {
    return (a ? a : '') + (b ? b : '') + c
  }

/*
  returns: String

  <ol>
  <li>Consume all code points until either
  a solidus (U+002F),
  a reverse solidus (U+005C),
  a question mark (U+003F),
  a number sign (U+0023),
  or the end of string is encountered.

  <li>Let $result be the <a title=cleanse>cleansed</a> set of code points using
  <var>null</var> as the encode set.

  <li>Remove leading U+0030 code points from $result until either the leading
  code point is not U+0030 or $result consists of exactly one code point. 

  <li>If any code points in $result are not <a>ASCII digits</a>:
    <ol>
    <li>If $input was not set, terminate processing with a
      <a>parse exception</a>.
    <li>Truncate $result starting with the first non-digit code point.
    <li>Indicate a <a>conformance error</a>.
    </ol>

  <li>Return the result as a string.
  </ol>

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=26446">bug 26446</a>
  may change port from a string to a number.
*/
Port
  = port:[^/\\?#]*
  {
    port = cleanse(port, null, 'port');
    var warn = port.exception;

    port = port.replace(/^0+(\d)/, '$1');
    if (!/^\d*$/.test(port)) {
      if (url) {
        warn = 'Invalid port number';
        port = port.replace(/\D.*/, '')
      } else {
        error('Invalid port number');
      }
    }

    if (warn) {
      port = new String(port);
      port.exception = warn
    };

    return port
  }

/*
  returns: Array of Strings

  <ol>
  <li>If any of the path separators are a reverse solidus ("\"), indicate
  a <a>conformance error</a>.

  <li>Extract all the pathnames into an array.  Process each name as follows:

    <ol>
    <li><a title=cleanse>Cleanse</a> the name using the
      <a>default encode set</a> as the encode set.
    <li>If the name is "." or "%2e" (case insensitive),
      then process this name based on the position in the array:
        <ol>
        <li>If the position is other than the last, remove the name from the
            list.
        <li>If the array is of length 1, replace the entry with an empty string.
        <li>Otherwise, leave the entry as is.
        </ol>
    <li>If the name is "..", ".%2e", "%2e.",
      or "%2e%2e" (all to be compared in a case insensitive manner),
      then process this name based on the position in the array:
        <ol>
        <li>If the position is the first, then remove it.
        <li>If the position is other than the last, then remove it and the
            one before it.
        <li>If the position is the last, then remove it and the one before it,
            then append an empty string.
        </ol>

  <li>Return the array.
  </ol>

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=24163">bug 24163</a>
  may change what code points to escape in the path.
*/
Path
  = path:([^/\\?#]* [/\\])* basename:[^/\\?#]*
  {
    var warn = null;

    path.push([basename]);

    for (var i=0; i<path.length; i++) {
      if (path[i][1] == "\\") {
        warn = 'Backslash ("\\") used as path segment delimiter'
      };

      path[i] = cleanse(path[i][0], Url.DEFAULT_ENCODE_SET, 'path');
      if (!warn && path[i].exception) warn = path[i].exception;

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
  returns: String

  Consume all code points until either a question mark (U+003F), a
  number sign (U+0023), or the end of string is encountered.
  Return the <a title=cleanse>cleansed</a> result using <var>null</var> as
  the encode set.

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=24246">bug 24246</a>
  may change what code points to escape in the scheme data.
*/
SchemeData
  = data:[^?#]*
  {
    return cleanse(data, null, 'scheme data');
  }

/*
  returns: String

  Consume all code points until either a 
  number sign (U+0023) or the end of string is encountered.
  Return the <a title=cleanse>cleansed</a> result using the
  the result using the <a>query encode set</a>.

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=27280">bug 27280</a>
  may change how code points < 0x20 are handled.
*/
Query 
  = query:[^#]*
  {
    return cleanse(query, Url.QUERY_ENCODE_SET, 'query')
  }

/*
  returns: String

  <ol>
  <li>Let $result be the remaining code points in the input.  
  <li>If any U+0000 characters are present in $result, remove those
  characters from $result and indicate a
  <a data-link-type="dfn" href="#conformance-error">conformance error</a>.
  <li>If any characters in $result are neither a Percent Sign (U+0025) nor
  a <a>URL code point</a>, indicate a
  <a data-link-type="dfn" href="#conformance-error">conformance error</a>.
  <li>Return the <a title=cleanse>cleansed</a> result using <var>null</var>
  as the encode set.
  </ol>

  <p class=note>Unfortunately not using 
  <a title="percent encode">percent-encoding</a> is intentional as
  implementations with majority market share exhibit this behavior.

  <!-- Chrome does percent-encoding if the scheme is not a relative scheme,
       hopefully that can be aligned since flip-flopping is not great. -->

  <p class=XXX>The resolution of
  <a href="https://www.w3.org/Bugs/Public/show_bug.cgi?id=26988">bug 26988</a>
  may add support for parsing URLs without decoding the fragment identifier.
*/
Fragment 
  = fragment:.*
  {
    for (var i=0; i<fragment.length; i++) {
      var c = fragment[i];
      if (c == "\u0000") {
        warn = "Null character in fragment";
        fragment.splice(i--, 1)
      } else if (c != '%' && !Url.URL_CODE_POINTS.test(c)) {
        warn = "Illegal character in fragment";
      }
    }

    return cleanse(fragment, null, 'fragment')
  }

/**
 * Setter Rules {#setter-rules}
 * ---
 *
 * <a href=#urlutils-and-urlutilsreadonly-members>URLUtils and
 * URLUtilsReadOnly members</a> invoke the following setter
 * rules with <code>url</code> set to a non-<code>null</code> value.
 */

/*
  Set $url.scheme to value returned by @Scheme.
*/
setProtocol
  = scheme:Scheme ':'? .*
{
  // XXX maybe disallow setting protocol to nonsensical values
  url._scheme = scheme
}

/*
  If $url.scheme_data is not null, return.

  Set $url.username to the 
  <a title="percent encode">percent encoded</a>
  value using the
  <a>username encode set</a>.
*/
setUsername
  = user:(.*)
  {
    if (url._scheme_data == null) {
      url._username = Url.percentEncode(user.join(''), Url.USERNAME_ENCODE_SET)
    }
  }

/*
  If $url.scheme_data is not null, return.

  Set $url.password to the 
  <a title="percent encode">percent encoded</a> value
  using the
  <a>password encode set</a>.
*/
setPassword
  = password:(.*)
  {
    if (url._scheme_data == null) {
      url._password = Url.percentEncode(password.join(''), Url.PASSWORD_ENCODE_SET)
    }
  }

/*
  If $url.scheme_data is not null, return.

  Set $url.host to the value returned by @Host.

  If @Port is present, set $result.port to its value.
*/
setHost
  = host:Host port:(':' Port)? ([/\\?#]? (.*))?
  {
    if (url._scheme_data == null) {
      url._host = host
      if (port) url._port = port[1]
    }
  }

/*
  If $url.scheme_data is not null, return.

  Set $url.host to the value returned by @Host.
*/
setHostname
  = host:Host [:/\\?#]? (.*)
  {
    if (url._scheme_data == null) {
      url._host = host
    }
  }

/*
  If $url.scheme_data is not null or $url.scheme is "file", return.

  If $url.scheme has a <a>default port</a>, and if @Port is equal to that
  default, then set the $port property of $url to the empty string.

  Otherwise, set $url.port to the value returned by @Port.
*/
setPort
  = port:Port [/\\?#]? (.*)
  {
    if (url._scheme_data == null && url._scheme != 'file') {
      if (Url.DEFAULT_PORT[url._scheme] == port) {
        url._port = '';
      } else {
        url._port = port;
      }
    }
  }

/*
  If $url.scheme_data is not null, return.

  Set $url.path to the value returned by @Path.
*/
setPathname
  = [/\\]? path:Path [/\\?#]? (.*)
  {
    if (url._scheme_data == null) {
      url._path = path
    }
  }

/*
  Set $url.query to the
  <a title="percent encode">percent encoded</a> value
  after the initial question mark (U+003F), if any, using the <a>query encode
  set</a>.
*/
setSearch
  = '?'? query:(.*)
  {
    url._query = Url.percentEncode(query.join(''), Url.QUERY_ENCODE_SET)
  }

/*
  Set $url.fragment to the 
  <a title="percent encode">percent encoded</a> value
  after the initial number sign (U+0023), if any, using the
  <a>simple encode set</a>
*/
setHash
  = '#'? fragment:(.*)
  {
    url._fragment = Url.percentEncode(fragment.join(''), Url.SIMPLE_ENCODE_SET)
  }

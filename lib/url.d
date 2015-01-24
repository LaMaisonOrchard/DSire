

/**
 Standard errors as definied by RFC2616 '6.1.1 Status Code and Reason Phrase',
 See also 'http://www.internetseer.com/help/error.xtp'.

 1xx: Informational - Request received, continuing process
 2xx: Success       - The action was successfully received, understood, and accepted
 3xx: Redirection   - Further action must be taken in order to complete the request
 4xx: Client Error  - The request contains bad syntax or cannot be fulfilled
 5xx: Server Error  - The server failed to fulfill an apparently valid request

 */
import std.string;
 
export class UrlException : Exception
{
    this(uint error, int line = __LINE__, string file = __FILE__)
    {
        super(Description(error).idup, file, line);
    }
    
    this(uint error, const(char)[] desciption, int line = __LINE__, string file = __FILE__)
    {
        super((Description(error) ~ desciption).idup, file, line);
    }
    
    private string Description(uint error)
    {
        if ((error in errorText) is null)
        {
            return "";
        }
        else
        {
            return errorText[error];
        }
    }
    
    private string ClassDescription(uint error)
    {
        int errorClass = error/ 100;
        
        if (errorClass > classText.length)
        {
            errorClass = 0;
        }
        
        return (classText[errorClass]);
    }
    
    private string[] classText =
    [
        "Unknown Error [%s:%d] [%d]",
        "Information [%s:%d] [%d]",
        "Success [%s:%d] [%d]",
        "Redirection [%s:%d] [%d]",
        "Client Error [%s:%d] [%d]",
        "Server Error [%s:%d] [%d]",
        "Code Error [%s:%d] [%d]",
    ];
    
    private enum string[uint] errorText =
    [
        100: " Continue",
        101: " Switching Protocols",
        200: " OK",
        201: " Created",
        202: " Accepted",
        203: " Non-Authoritative Information",
        204: " No Content",
        205: " Reset Content",
        206: " Partial Content",
        300: " Multiple Choices",
        301: " Moved Permanently",
        302: " Found",
        303: " See Other",
        304: " Not Modified",
        305: " Use Proxy",
        307: " Temporary Redirect",
        400: " Bad Request",
        401: " Unauthorized",
        402: " Payment Required",
        403: " Forbidden",
        404: " Not Found",
        405: " Method Not Allowed",
        406: " Not Acceptable",
        407: " Proxy Authentication Required",
        408: " Request Time-out",
        409: " Conflict",
        410: " Gone",
        411: " Length Required",
        412: " Precondition Failed",
        413: " Request Entity Too Large",
        414: " Request-URI Too Large",
        415: " Unsupported Media Type",
        416: " Requested range not satisfiable",
        417: " Expectation Failed",
        500: " Internal Server Error",
        501: " Not Implemented",
        502: " Bad Gateway",
        503: " Service Unavailable",
        504: " Gateway Time-out",
        505: " Service Version not supported",
        600: " Invalid type",
        601: " Invalid character encoding",
        602: " Invalid cast",
        603: " Duplicate scheme definition",
    ];
}

/**
 Decode the constituent parts of the URL. See RFC3986 January 2005
 */
export struct Url
{
    enum Host
    {
        Undefined,
        IpLiteral,
        IPv4,
        Name,
    };

    string _scheme;
    string _user_info;
    string _host;
    Host   _type;
    string _port;
    string _path;
    string _query;
    string _fragment;
       

    @property
    {
         string scheme()   const {return _scheme;}
         string userInfo() const {return _user_info;}
         string host()     const {return _host;}
         Host   hostType() const {return _type;}
         string port()     const {return _port;}
         string path()     const {return _path;}
         string query()    const {return _query;}
         string fragment() const {return _fragment;}
        
         /**
         Expand the URL to a full URL description.
         */
         string url()  // TODO
         {
            string rtn;
            
            auto scheme = _scheme;
            if (scheme != "file")
            {
               rtn = scheme ~ ":";
            }
            
            rtn ~= _path;
            
            return rtn;
         }
    }      
        
    /**
     Construct the object from the URL description
     */    
    this(in  const(char)[] src_url)
    {
        char[] scheme;
        char[] user_info;
        char[] host;
        char[] port;
        char[] path;
        char[] query;
        char[] fragment;

        // Take a working copy of the URL
        const(char)[] url = src_url;
        
        /**
         Decode the first two character as a HEX char value
         */
        char hexCode(in const(char)[] url)
        {
            char ch = 0;
                            
            if (url.length < 2)
            {
                // Error - needs two hex digits
                throw new UrlException(601);
            }
            
            switch (url[0])
            {
                case '0': .. case '9':
                    ch |= ((url[0] - '0') +  0) << 4;
                    break;
                    
                case 'a': .. case 'z':
                    ch |= ((url[0] - 'a') + 10) << 4;
                    break;
                    
                case 'A': .. case 'Z':
                    ch |= ((url[0] - 'A') + 10) << 4;
                    break;
                    
                default:
                    // Illegal Hex value
                    throw new UrlException(601);
            }
            
            switch (url[1])
            {
                case '0': .. case '9':
                    ch |= ((url[1] - '0') +  0) << 0;
                    break;
                    
                case 'a': .. case 'z':
                    ch |= ((url[1] - 'a') + 10) << 0;
                    break;
                    
                case 'A': .. case 'Z':
                    ch |= ((url[1] - 'A') + 10) << 0;
                    break;
                    
                default:
                    // Illegal Hex value
                    throw new UrlException(601);
            }
            
            return ch;
        }
        
        /**
         Extract the authority information from the start of the URL
         */
        void getAuth(ref const(char)[] url, ref char[] user_info,
                                            ref char[] host,
                                            ref char[] port)
        {
            /**
             Extract the user identifier from the start of the URL.  
             */
            void getUserInfo(ref const(char)[] url, ref char[] user_info)
            {
                int i = 0;
                
                while (i < url.length)
                {
                    switch(url[i])
                    {
                        // unreserved / sub-delims / ':'
                        case 'a': .. case 'z':
                        case 'A': .. case 'Z':
                        case '0': .. case '9':
                        case '-', '.', '_', '~',
                             '!', '$', '&', '\'', '(', ')',
                             '*', '+', ',', ';', '=', ':':
                            // Valid character
                            i += 1;
                            break;
                        
                        case '%':
                            // PCT Encoded
                            
                            // Copy what we have so far
                            path ~= url[0..i];
                            url   = url[i+1..$];
                            i = 0;
                            
                            // Add the encoded value
                            path ~= hexCode(url);
                            url   = url[2..$];
                               
                            break;
                        
                        case '@':
                            // End of user info
                            user_info ~= url[0..i];
                            url        = url[i+1..$];
                            break;
                            
                        default:
                            // No user info present
                            return;
                    }
                }
                
                // No user info present
            }


            /**
             Extract the host identifier from the start of the URL. This
             coud be a host name or and IP address.
             */
            void getHost(ref const(char)[] url, ref char[] host)
            {        
                /**
                 Extract the IP Literal value from the start of the URL. This
                 strips the containg brackets ([...]).
                 */
                void getIpLiteral(ref const(char)[] url, ref char[] host)
                {
                    // This is a really cheap implementation !!!
                    // Just look for the closing bracket

                    for (int i = 1; (i < url.length); i++)
                    {
                        if (url[i] == ']')
                        {
                            host   ~= url[1..i];
                            url     = url[i+1..$];
                            _type  = Host.IpLiteral;
                            return;
                        }
                    }

                    // No closing bracket
                    throw new UrlException(502, url);
                }
             
                /**
                 Extract the IPv4 value from the start of the URL. This
                 is four dot separated decimal values. The decimal values
                 must be in the range 0-255. However, that is not checked!
                 */
                void getIpv4(ref const(char)[] url, ref char[] host)
                {
                    int i;
                    int digit;

                    for (int octet = 0; (octet < 4); octet += 1)
                    {
                        // Read an octet
                        digit = 0;
                        while ((i < url.length) && (digit < 3) &&
                               ('0' <= url[i]) && (url[i] <= '9'))
                        {
                            i     += 1;
                            digit += 1;
                        }

                        // There must be at least one digit
                        if (digit == 0)
                        {
                            throw new UrlException(502, url);
                        }
                        // If this is not the last octet
                        else if (octet < 3)
                        {
                            // There must be a dot separator
                            if (url[i] != '.')
                            {
                                throw new UrlException(502, url);
                            }

                            // Skip over the dot separator
                            i += 1;
                        }
                    }

                    host   ~= url[0..i];
                    url     = url[i..$];
                    _type  = Host.IPv4;
                }
           
                /**
                 Extract the host name from the start of the URL.
                 */
                void getHostName(ref const(char)[] url, ref char[] host)
                {
                    int i = 0;
                    
                    while (i < url.length)
                    {
                        switch(url[i])
                        {
                            // unreserved / sub-delims
                            case 'a': .. case 'z':
                            case 'A': .. case 'Z':
                            case '0': .. case '9':
                            case '-', '.', '_', '~',
                                 '!', '$', '&', '\'', '(', ')',
                                 '*', '+', ',', ';', '=':
                                // Valid character
                                i += 1;
                                break;
                            
                            case '%':
                                // PCT Encoded
                                
                                // Copy what we have so far
                                host ~= url[0..i];
                                url   = url[i+1..$];
                                i = 0;
                                
                                // Add the encoded value
                                path ~= hexCode(url);
                                url   = url[2..$];
                                   
                                break;
                                
                            default:
                                // End of path
                                host   ~= url[0..i];
                                url     = url[i..$];
                                _type  = Host.Name;
                                return;
                        }
                    }
                    
                    // End of path
                    host   ~= url[0..$];
                    url     = "";
                    _type  = Host.Name;
                }
        
                switch(url[0])
                {
                    // IP-literal
                    case '[': 
                        getIpLiteral(url, host);
                        break;

                    // IPv4
                    case '1': .. case '9': 
                        getIpv4(url, host);
                        break;

                    // reg-name
                    // unreserved / sub-delims / pct-encoded
                    // !!! This does not permit leading digits !!!
                    case 'a': .. case 'z':  
                    case 'A': .. case 'Z':
                    case '-', '.', '_', '~',
                         '!', '$', '&', '\'', '(', ')',
                         '*', '+', ',', ';', '=', '%':
                        getHostName(url, host);
                        break;

                    // Illegal host identifier
                    default:
                        throw new UrlException(502, url);
                }
            }


            /**
             Extract the port number from the start of the URL. The port
             number is a string of decimal digits. The value of the port
             number must be < 2^16. But this is not checked.
             */
            void getPort(ref const(char)[] url, ref char[] port)
            {
                int i = 0;
                
                while (i < url.length)
                {
                    switch(url[i])
                    {
                        // Decimal
                        case '0': .. case '9':
                            // Valid character
                            i += 1;
                            break;
                            
                        default:
                            // End of path
                            port ~= url[0..i];
                            url   = url[i..$];
                            return;
                    }
                }
                
                // End of path
                port ~= url[0..$];
                url   = "";
            }

            getUserInfo(url, user_info);

            if (url.length > 0)
            {
                getHost(url, host);
            }

            if ((url.length > 0) && (url[0] == ':'))
            {
                url = url[1..$];
                getPort(url, port);
            }
        }
        
        /**
         Extract a valid path sequence from the start of the URL

         This implementation permits spaces in paths which is non-standard
         URL but is consistent with normal file path. In addition DOS path
         separators are permitted and converted to standard path separators.
         */
        void getPath(ref const(char)[] url, ref char[] path)
        {
            int i = 0;
            
            while (i < url.length)
            {
                switch(url[i])
                {
                    // pchar
                    case 'a': .. case 'z':
                    case 'A': .. case 'Z':
                    case '0': .. case '9':
                    case '-', '.', '_', '~',
                         '!', '$', '&', '\'', '(', ')',
                         '*', '+', ',', ';', '=',
                         ':', '@', '/', ' ':
                        // Valid character
                        i += 1;
                        break;
                    
                    // Windows path separator
                    case '\\':
                        path ~= url[0..i];
                        path ~= '/';
                        url   = url[i+1..$];
                        i = 0;
                        break;
                    
                    case '%':
                        // PCT Encoded
                        
                        // Copy what we have so far
                        path ~= url[0..i];
                        url   = url[i+1..$];
                        i = 0;
                        
                        // Add the encoded value
                        path ~= hexCode(url);
                        url   = url[2..$];
                        break;
                        
                    default:
                        // End of path
                        path ~= url[0..i];
                        url   = url[i..$];
                        return;
                }
            }
            
            // End of path
            path ~= url[0..$];
            url   = "";
        }
        
        /**
         Extract the scheme identifier from the start of the URL (if any)
         */
        void getScheme(ref const(char)[] url, ref char[] scheme)
        {
            uint i = 0;
            
            switch (url[i])
            {
                case 'a': .. case 'z':
                case 'A': .. case 'Z':
                    i += 1;
                    while (i < url.length)
                    {
                        switch (url[i])
                        {
                            case 'a': .. case 'z':
                            case 'A': .. case 'Z':
                            case '0': .. case '9':
                            case '+', '-', '.':
                                // Valid character continue
                                i += 1;
                                break;
                                
                            case ':':
                                // End of scheme
                                scheme ~= url[0..i];
                                url     = url[i+1..$];
                                
                                // Finish
                                return;
                                
                            default:
                                // Assume no scheme specified
                                // Finish
                                return;
                        }
                    }
                    break;
                    
                default:
                    // Assume no scheme specified
                    break;
            }
        }
        
        /**
         Extract the hierarchical part from the start of the URL (if any)
         */
        void getHierPart(ref const(char)[] url, ref char[] user_info,
                                                ref char[] host,
                                                ref char[] port,
                                                ref char[] path)
        {
            switch (url[0])
            {
                // Absolute or Hierchical case
                case '/':
                    if ((url.length > 1) && (url[1] == '/'))
                    {
                        // Authority 
                        url = url[2..$];
                        getAuth(url, user_info, host, port);
                        
                        // Absolute/Empty path
                        if ((url.length > 0) &&
                            ((url[0] == '/') || (url[0] == '\\')))
                        {
                            getPath(url, path);
                        }
                        else
                        {
                            // Empty path
                        }
                    }
                    else
                    {
                        // Absolute path
                        getPath(url, path);
                        _type = Host.Undefined;
                    }
                    break;
                    
                // Windows path separator
                case '\\':
                    // Absolute path
                    getPath(url, path);
                    _type = Host.Undefined;
                    break;
                    
                // pchar
                case 'a': .. case 'z':
                case 'A': .. case 'Z':
                case '0': .. case '9':
                case '-', '.', '_', '~',
                     '!', '$', '&', '\'', '(', ')',
                     '*', '+', ',', ';', '=',
                     ':', '@', '%':
                    // Valid character continue
                    getPath(url, path);
                    _type = Host.Undefined;
                    break;
                    
                default:
                    // Empty path
                    _type = Host.Undefined;
                    break;
            }
        }
        
        /**
         Extract the query or fragment part part from the start of the URL
         */
        void getAdenda(ref const(char)[] url, ref char[] adenda)
        {
            int i = 0;
            
            while (i < url.length)
            {
                switch (url[i])
                {
                    // pchar
                    case 'a': .. case 'z':
                    case 'A': .. case 'Z':
                    case '0': .. case '9':
                    case '-', '.', '_', '~',
                         '!', '$', '&', '\'', '(', ')',
                         '*', '+', ',', ';', '=',
                         ':', '@', '/', '?':
                        // Valid character continue
                        i += 1;
                        break;
                        
                    case '%':
                        // PCT Encoded
                        
                        // Copy what we have so far
                        adenda ~= url[0..i];
                        url     = url[i+1..$];
                        i = 0;
                        
                        // Add the encoded value
                        query ~= hexCode(url);
                        url   = url[2..$];
                           
                        break;
                        
                    default:
                        // End of query
                        adenda ~= url[0..i];
                        url     = url[i..$];
                        return;
                }
            }
        
            // End of path
            adenda ~= url[0..$];
            url     = "";
        }
        
        if (url.length > 0)
        {
            getScheme(url, scheme);
        }

        if (url.length > 0)
        {
            getHierPart(url, user_info, host, port, path);
        }
        
        if ((url.length > 0) && (url[0] == '?'))
        {
            url = url[1..$];
            getAdenda(url, query);
        }
        
        if ((url.length > 0) && (url[0] == '#'))
        {
            url = url[1..$];
            getAdenda(url, fragment);
        }

        if (_scheme.length == 0)
        {
            // Default scheme
            _scheme = "file";
        }
        else
        {
            _scheme = toLower(scheme).idup;
        }
        _user_info  = user_info.idup;
        _host       = host.idup;
        _port       = port.idup;
        _path       = path.idup;
        _query      = query.idup;
        _fragment   = fragment.idup;
    }

    
    /**
     Break the path down into segment. If the path is relative
     then it will extend 'context'. All '', '.' and '..' segments
     that can be resolved will be removed.
     */
    string[] Segments(string[] context = (string[]).init) const 
    {
        string[] segs;
        int end;   // The current end of the segments
        int start; // Start of the current segment
        int idx;   // The path possition

        if (_path.length == 0)
        {
            // Empty (relative) pat
            return context;
        }
        else if (_path[0] == '/')
        {
            // Absolute path
            segs.length = 8;
            end   = 0;
            start = 1;
            idx   = 1;
        }
        else
        {
            // Relative path
            segs  = context;
            end   = cast(int)(context.length);
            start = 0;
            idx   = 0;
        }

        // Work through each segment and add it to the list
        while (idx < _path.length)
        {
            // Get the next segment
            while ((idx < _path.length) && (_path[idx] != '/'))
            {
                idx += 1;
            }

            // Check for space
            if (end >= segs.length)
            {
                segs.length = 2*end;
            }

            switch (_path[start..idx])
            {
                case "":
                    // Empty segment - discard
                    break;

                case ".":
                    // Null segment - discard
                    break;

                case "..":
                    // Move up a segment
                    if ((end > 0) && (segs[end-1] != ".."))
                    {
                        // Discard the top segment
                        end -= 1;
                    }
                    else
                    {
                        // Can't move up so add this as a segment
                        segs[end++] = _path[start..idx];
                    }
                    break;

                default:
                    // Add this as a segment
                    segs[end++] = _path[start..idx];
                    break;
            }
            
            idx   += 1;
            start  = idx;
        }
        

        return segs[0..end];
    }
}

unittest
{
    struct TestCase
    {
        public:
   
            string   url;
            string   scheme;
            string   userInfo;
            string   host;
            Url.Host hostType;
            string   port;
            string   path;
            string   query;
            string   fragment;
    }

    static TestCase testCases[] =
    [
        // Test 1
        {"", 
            "file",
            "",
            "",
            Url.Host.Undefined,
            "",
            "",
            "",
            ""},

        // Test 2
        {"fred", 
            "file",
            "",
            "",
            Url.Host.Undefined,
            "",
            "fred",
            "",
            ""},

        // Test 3
        {"dev:/stdio", 
            "dev",
            "",
            "",
            Url.Host.Undefined,
            "",
            "/stdio",
            "",
            ""},

        // Test 4
        {"dev:\\stdio", 
            "dev",
            "",
            "",
            Url.Host.Undefined,
            "",
            "/stdio",
            "",
            ""},

        // Test 5
        {"dev://stdio", 
            "dev",
            "",
            "stdio",
            Url.Host.Name,
            "",
            "",
            "",
            ""},

        // Test 6
        {"dev://fred@", 
            "dev",
            "fred",
            "",
            Url.Host.Undefined,
            "",
            "",
            "",
            ""},

        // Test 7
        {"dev://fred@home", 
            "dev",
            "fred",
            "home",
            Url.Host.Name,
            "",
            "",
            "",
            ""},

        // Test 8
        {"dev://fred@home:1234", 
            "dev",
            "fred",
            "home",
            Url.Host.Name,
            "1234",
            "",
            "",
            ""},

        // Test 9
        {"dev://fred@256.128.18.7", 
            "dev",
            "fred",
            "256.128.18.7",
            Url.Host.IPv4,
            "",
            "",
            "",
            ""},

        // Test 10
        {"dev://fred@256.128.18.7:1234", 
            "dev",
            "fred",
            "256.128.18.7",
            Url.Host.IPv4,
            "1234",
            "",
            "",
            ""},

        // Test 11
        {"dev://fred@[1:2:3:4;5:6]", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "",
            "",
            "",
            ""},

        // Test 12
        {"dev://fred@[1:2:3:4;5:6]:1234", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "1234",
            "",
            "",
            ""},

        // Test 13
        {"dev://fred@[1:2:3:4;5:6]:1234/harold", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "1234",
            "/harold",
            "",
            ""},

        // Test 14
        {"dev://fred@[1:2:3:4;5:6]:1234/harold/lois", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "1234",
            "/harold/lois",
            "",
            ""},

        // Test 15
        {"dev://fred@[1:2:3:4;5:6]:1234\\harold\\lois", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "1234",
            "/harold/lois",
            "",
            ""},

        // Test 16
        {"dev://fred@[1:2:3:4;5:6]:1234\\harold\\lois?fred=bill?lois=steve", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "1234",
            "/harold/lois",
            "fred=bill?lois=steve",
            ""},

        // Test 17
        {"dev://fred@[1:2:3:4;5:6]:1234\\harold\\lois#fred=bill?lois=steve", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "1234",
            "/harold/lois",
            "",
            "fred=bill?lois=steve"},

        // Test 18
        {"dev://fred@[1:2:3:4;5:6]:1234\\harold\\lois?a=b=c=d?goat#fred=bill?lois=steve", 
            "dev",
            "fred",
            "1:2:3:4;5:6",
            Url.Host.IpLiteral,
            "1234",
            "/harold/lois",
            "a=b=c=d?goat",
            "fred=bill?lois=steve"},

        // Test 19
        {".", 
            "file",
            "",
            "",
            Url.Host.Undefined,
            "",
            ".",
            "",
            ""},

        // Test 20
        {"..", 
            "file",
            "",
            "",
            Url.Host.Undefined,
            "",
            "..",
            "",
            ""},

        // Test 21
        {"/lois", 
            "file",
            "",
            "",
            Url.Host.Undefined,
            "",
            "/lois",
            "",
            ""},

        // Test 22
        {"\\lois", 
            "file",
            "",
            "",
            Url.Host.Undefined,
            "",
            "/lois",
            "",
            ""},

        // Test 23
        {"\\lois falla", 
            "file",
            "",
            "",
            Url.Host.Undefined,
            "",
            "/lois falla",
            "",
            ""},

        // Test 24
        {"DEV:/stdio", 
            "dev",
            "",
            "",
            Url.Host.Undefined,
            "",
            "/stdio",
            "",
            ""},

        //~ // Test 25
        //~ {"../../fred/..", 
            //~ "",
            //~ "",
            //~ "",
            //~ Url.Host.Undefined,
            //~ "",
            //~ "../..",
            //~ "",
            //~ ""},
    ];

    foreach (int i, TestCase test; testCases)
    {
        //writeln("Test ", i);
        Url url = new Url(test.url);
        assert( test.scheme   == url.scheme );
        assert( test.userInfo == url.userInfo );
        assert( test.host     == url.host );
        assert( test.hostType == url.hostType );
        assert( test.port     == url.port );
        assert( test.path     == url.path );
        assert( test.query    == url.query );
        assert( test.fragment == url.fragment );
    }
}
import java.io.FileReader;
import java.util.Iterator;
import java.util.HashMap;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import io.mola.galimatias.URL;
import io.mola.galimatias.URLParsingSettings;
import io.mola.galimatias.ErrorHandler;
import io.mola.galimatias.GalimatiasParseException;

public class testgalimatias {

  @SuppressWarnings("unchecked")
  public static void main(String[] args) throws Exception {
    new testgalimatias().run();
  }

  private GalimatiasParseException errorException;
  private GalimatiasParseException fatalErrorException;

  @SuppressWarnings("unchecked")
  public void run() throws Exception {
    JSONParser parser = new JSONParser();
    JSONArray tests = (JSONArray) parser.parse(new
      FileReader("urltestdata.json"));
    Iterator<?> iterator = tests.iterator();

    HashMap<String, Integer> DEFAULT_PORTS = new HashMap<String, Integer>();
    DEFAULT_PORTS.put("ftp", 21);
    DEFAULT_PORTS.put("http", 80);
    DEFAULT_PORTS.put("gopher", 70);
    DEFAULT_PORTS.put("http", 80);
    DEFAULT_PORTS.put("https", 443);
    DEFAULT_PORTS.put("ws", 80);
    DEFAULT_PORTS.put("wss", 443);

    URLParsingSettings settings = URLParsingSettings.create().
      withErrorHandler(new ErrorHandler() {
        @Override
        public void error(GalimatiasParseException error) throws GalimatiasParseException {
          errorException = error;
        }

        @Override
        public void fatalError(GalimatiasParseException error) {
          fatalErrorException = error;
        }
      });

    JSONArray results = new JSONArray();
    while (iterator.hasNext()) {
      JSONObject test = (JSONObject) iterator.next();
      JSONObject result = new JSONObject();
      result.put("base", test.get("base"));
      result.put("input", test.get("input"));
      errorException = fatalErrorException = null;

      try {
        URL base = URL.parse((String) test.get("base"));
        URL url = URL.parse(settings, base, (String) test.get("input"));
        result.put("href", url.toString());
        result.put("protocol", url.scheme() + ':');
        result.put("username", url.username());
        result.put("password", (url.password()!=null) ? url.password() : "");
        result.put("hostname", (url.host()!=null) ? url.host() : "");

        if (url.port() == -1 || url.port()==DEFAULT_PORTS.get(url.scheme())) {
          result.put("port", "");
        } else {
          result.put("port", url.port());
        }

        result.put("pathname", url.path());
        result.put("search", (url.query()!=null) ? "?"+url.query() : "");
        result.put("hash", (url.fragment()!=null) ? "#"+url.fragment() : "");
        if (fatalErrorException != null) {
          result.put("exception", fatalErrorException.getMessage());
        } else if (errorException != null) {
          result.put("exception", errorException.getMessage());
        }
      } catch (Exception e) {
        result.put("href", test.get("input"));
        result.put("exception", 
          (e.getMessage()!=null) ? e.getMessage() : e.toString());
        result.put("protocol", ":");
        result.put("username", "");
        result.put("password", "");
        result.put("hostname", "");
        result.put("port", "");
        result.put("pathname", "");
        result.put("search", "");
        result.put("hash", "");
      }
      results.add(result);
    }
    System.out.println(results.toString());
  }
}

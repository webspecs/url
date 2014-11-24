import java.io.FileInputStream;
import java.util.Iterator;
import java.util.HashMap;
import org.json.JSONTokener;
import org.json.JSONObject;
import org.json.JSONArray;
import io.mola.galimatias.URL;
import io.mola.galimatias.URLParsingSettings;
import io.mola.galimatias.ErrorHandler;
import io.mola.galimatias.GalimatiasParseException;

public class testgalimatias {

  public static void main(String[] args) throws Exception {
    new testgalimatias().run();
  }

  private GalimatiasParseException errorException;
  private GalimatiasParseException fatalErrorException;

  public void run() throws Exception {
    String useragent = "unknown";

    String[] paths = System.getProperty("java.class.path").split(":");
    for (int i=0; i<paths.length; i++) {
      if (paths[i].startsWith("galimatias-")) {
        useragent = paths[i].substring(0, paths[i].lastIndexOf('.'));
      }
    }

    JSONArray tests = new JSONArray(new JSONTokener(new FileInputStream("urltestdata.json")));

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
    for (int i=0; i<tests.length(); i++) {
      JSONObject test = tests.getJSONObject(i);
      JSONObject result = new JSONObject();
      result.put("base", test.get("base"));
      result.put("input", test.get("input"));
      errorException = fatalErrorException = null;

      try {
        URL base = URL.parse(test.getString("base"));
        URL url = URL.parse(settings, base, test.getString("input"));
        result.put("href", url.toString());
        result.put("protocol", url.scheme() + ':');
        result.put("username", url.username());
        result.put("password", url.password());
        result.put("hostname", 
          (url.host()!=null ? url.host().toHumanString() : null));

        if (url.port() == -1 || url.port()==DEFAULT_PORTS.get(url.scheme())) {
          result.put("port", (String)null);
        } else {
          result.put("port", url.port());
        }

        result.put("pathname", url.path());
        result.put("search", (url.query()!=null && !url.query().isEmpty()) ? "?"+url.query() : "");
        result.put("hash", (url.fragment()!=null && !url.fragment().isEmpty()) ? "#"+url.fragment() : "");

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
        result.put("password", (String)null);
        result.put("hostname", "");
        result.put("port", "");
        result.put("pathname", "");
        result.put("search", (String)null);
        result.put("hash", (String)null);
      }
      results.put(result);
    }

    JSONObject output = new JSONObject();
    output.put("useragent", useragent);
    output.put("constructor", results);

    System.out.println(output.toString(2));
  }
}

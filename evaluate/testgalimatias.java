import java.io.FileReader;
import java.util.Iterator;
import java.util.HashMap;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import io.mola.galimatias.URL;

public class testgalimatias {

  @SuppressWarnings("unchecked")
  public static void main(String[] args) throws Exception {
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

    JSONArray results = new JSONArray();
    while (iterator.hasNext()) {
      JSONObject test = (JSONObject) iterator.next();
      JSONObject result = new JSONObject();
      result.put("base", test.get("base"));
      result.put("input", test.get("input"));
      try {
        URL base = URL.parse((String) test.get("base"));
        URL url = URL.parse(base, (String) test.get("input"));
        result.put("href", url.toString());
        result.put("protocol", url.scheme() + ':');
        result.put("username", url.username());
        result.put("password", (url.password()!=null) ? url.password() : "");
        result.put("hostname", url.host().toString());
        result.put("port", 
          (url.port()==DEFAULT_PORTS.get(url.scheme())) ? "" : url.port());
        result.put("pathname", url.path());
        result.put("search", (url.query()!=null) ? "?"+url.query() : "");
        result.put("hash", (url.fragment()!=null) ? "#"+url.fragment() : "");
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

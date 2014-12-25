using System;
using System.Reflection;
using System.Json;

class testuri {
  static void Main(string[] args) {
    var text = System.IO.File.ReadAllText(args[0]);
    var json = (JsonArray)JsonValue.Parse(text);
    var constructors = new JsonArray();

    foreach (JsonObject test in json) {
      var result = new JsonObject();
      result["input"] = test["input"];
      result["base"] = test["base"];

      try {
        var base_uri = new Uri((string)test["base"]);
        var uri = new Uri(base_uri, (string)test["input"]);

        result["href"] = uri.ToString();
        result["protocol"] = uri.Scheme + ":";

        if (uri.UserInfo != "") {
           var parts = uri.UserInfo.Split(":".ToCharArray(), 2);
           result["username"] = parts[0];
           if (parts.Length > 1) result["password"] = parts[1];
        }

        result["hostname"] = uri.Host;

        if (!uri.IsDefaultPort && uri.Port != -1) {
          result["port"] = uri.Port;
        }

        result["pathname"] = String.Join("", uri.Segments);

        if (uri.Query != "") {
          result["search"] = uri.Query;
        }

        if (uri.Fragment != "") {
          result["hash"] = uri.Fragment;
        }
      } catch(System.UriFormatException e) {
        result["exception"] = e.Message;
      }

      constructors.Add(result);
    }

    var output = new JsonObject();

    var assembly = Assembly.GetExecutingAssembly();
    foreach (var name in assembly.GetReferencedAssemblies()) {
      if (name.Name == "System") {
        output["useragent"] = name.ToString();
      }
    }

    output["constructor"] = constructors;

    // workaround System.Json bugs
    Console.WriteLine(output.ToString().Replace("\n", "\\n").
      Replace("\t", "\\t").Replace("\u0000", "\\u0000"));
  }
}

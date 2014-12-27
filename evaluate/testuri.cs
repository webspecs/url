using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using Newtonsoft.Json;

public class Output {
  public string useragent;
  public List<Dictionary<string, string>> constructor;
}

class testuri {
  static void Main(string[] args) {
    var text = System.IO.File.ReadAllText(args[0], Encoding.UTF8);
    List<Dictionary<string, string>> tests =
      JsonConvert.DeserializeObject<List<Dictionary<string, string>>>(text);
    var constructors = new List<Dictionary<string, string>>();

    foreach (var test in tests) {
      var result = new Dictionary<string, string>();
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
          result["port"] = uri.Port.ToString();
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
        result["href"] = (string)test["input"];
        result["protocol"] = ":";
      }

      constructors.Add(result);
    }

    var output = new Output();

    var assembly = Assembly.GetExecutingAssembly();
    foreach (var name in assembly.GetReferencedAssemblies()) {
      if (name.Name == "System") {
        output.useragent = name.ToString();
      }
    }

    output.constructor = constructors;

    var json = JsonConvert.SerializeObject(output, Formatting.Indented);
    System.IO.File.WriteAllText(args[1],  json, new UTF8Encoding(false));
  }
}

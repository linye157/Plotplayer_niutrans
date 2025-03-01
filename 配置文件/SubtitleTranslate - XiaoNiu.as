// User-Agent string for HTTP requests
string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36";

// Supported language codes (assumed to match Google's for simplicity)
array<string> LangTable = 
{
    "af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bs", "bg", "my", "ca", "ceb", "ny",
    "zh", "cht", "co", "hr", "cs", "da", "nl", "en", "eo", "et", "tl", "fi", "fr",
    "fy", "gl", "ka", "de", "el", "gu", "ht", "ha", "haw", "iw", "hi", "hmn", "hu", "is", "ig",
    "id", "ga", "it", "ja", "jw", "kn", "kk", "km", "ko", "ku", "ky", "lo", "la", "lv", "lt",
    "lb", "mk", "ms", "mg", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no", "ps", "fa", "pl",
    "pt", "pa", "ro", "romanji", "ru", "sm", "gd", "sr", "st", "sn", "sd", "si", "sk", "sl",
    "so", "es", "su", "sw", "sv", "tg", "ta", "te", "th", "tr", "uk", "ur", "uz", "vi", "cy",
    "xh", "yi", "yo", "zu"
};

// Global variable to store the API key
string api_key;

// Metadata Functions
string GetTitle()
{
    return "Xiaoniu translate";
}

string GetVersion()
{
    return "1";
}

string GetDesc()
{
    return "https://trans.neu.edu.cn/";
}

// Login Dialog Functions
string GetLoginTitle()
{
    return "Input Xiaoniu API key";
}

string GetLoginDesc()
{
    return "Input Xiaoniu API key";
}

string GetUserText()
{
    return "API key:";
}

string GetPasswordText()
{
    return ""; // No password required
}

// Authentication Functions
string ServerLogin(string User, string Pass)
{
    api_key = User;
    if (api_key.empty()) return "fail";
    return "200 ok";
}

void ServerLogout()
{
    api_key = "";
}

// Language Selection Functions
array<string> GetSrcLangs()
{
    return LangTable; // No "auto" option, as Xiaoniu requires a specified source language
}

array<string> GetDstLangs()
{
    return LangTable;
}

// JSON Parsing Function for Xiaoniu API Response
string JsonParseXiaoniu(string json)
{
    JsonReader Reader;
    JsonValue Root;
    
    if (Reader.parse(json, Root) && Root.isObject())
    {
        JsonValue code = Root["code"];
        if (code.isInt() && code.asInt() == 200)
        {
            JsonValue data = Root["data"];
            if (data.isArray())
            {
                string ret = "";
                for (int i = 0; i < data.size(); i++)
                {
                    JsonValue item = data[i];
                    if (item.isObject())
                    {
                        JsonValue sentences = item["sentences"];
                        if (sentences.isArray())
                        {
                            for (int j = 0; j < sentences.size(); j++)
                            {
                                JsonValue sentence = sentences[j];
                                if (sentence.isObject())
                                {
                                    JsonValue translatedText = sentence["data"];
                                    if (translatedText.isString())
                                    {
                                        if (!ret.empty()) ret += "";
										ret += translatedText.asString();
                                    }
                                }
                            }
                        }
                    }
                }
                return ret;
            }
        }
        else
        {
            JsonValue msg = Root["msg"];
            if (msg.isString()) return "Error: " + msg.asString();
        }
    }
    return ""; // Return empty string on parsing failure or error
}

// Main Translation Function
string Translate(string Text, string &in SrcLang, string &in DstLang)
{
    // Check if API key is set
    if (api_key.empty()) return "API key not set";

    // Default source language to "en" if not specified (unlike Google, no "auto" support)
    if (SrcLang.empty()) SrcLang = "en";

    // Construct the API URL with the API key
    //string url = "https://trans.neu.edu.cn/niutrans/textTranslation?apikey=" + api_key;
	string url = "https://trans.neu.edu.cn/niutrans/textTranslation?apikey=b18352607b8cb0e9dfe51e26b8853482" ;

    // Escape the text for JSON
    string escapedText = Text;
    escapedText.replace("\\", "\\\\");
    escapedText.replace("\"", "\\\"");
    escapedText.replace("\n", "\\n");
    escapedText.replace("\r", "\\r");
    escapedText.replace("\t", "\\t");

    // Build the JSON body
    string jsonBody = "{\"from\":\"" + SrcLang + "\",\"to\":\"" + DstLang + "\",\"src_text\":\"" + escapedText + "\"}";

    // Set the request header for JSON
    string SendHeader = "Content-Type: application/json";

    // Send the POST request
    string text = HostUrlGetString(url, UserAgent, SendHeader, jsonBody);

    // Parse the response
    string ret = JsonParseXiaoniu(text);

    // If translation is successful, set encoding and return
    if (ret.length() > 0)
    {
        SrcLang = "UTF8";
        DstLang = "UTF8";
        return ret;
    }
    return ""; // Return empty string if translation fails
}
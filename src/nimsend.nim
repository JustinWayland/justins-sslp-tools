import std/parsecfg
import std/paths
import std/appdirs
import std/streams
import std/strutils
import std/os
import std/[mimetypes, httpclient]
import std/[strtabs,json,jsonutils]
import cligen

type 
    MissingOptionException = object of ValueError

proc nimsend(output: string = "output.json", args: seq[string]): int =
    let configPath: Path = appdirs.getConfigDir() / Path("nimsend") / Path("nimsend.ini")
    var configStream = newFileStream(configPath.string, fmRead)
    assert configStream != nil, "can't read required configuration file " & configPath.string
    var username: string
    var password: string
    var mb_limit: int
    try: 
        var settings: Config = loadConfig(configStream.Stream, configPath.string)
        username = settings.getSectionValue("", "username", "")
        if username == "":
            raise newException(MissingOptionException, "username must be specified in the default section of the file")
        password = settings.getSectionValue("", "password", "")
        if password == "":
            raise newException(MissingOptionException, "password must be specified in the default section of the file")
        mb_limit = parseInt(settings.getSectionValue("", "mb_limit", "2"))
        echo "username: " & username
        echo "password: " & password
        echo "mb_limit: " & $mb_limit
    finally:
        configStream.close()
    var httpClient = newHttpClient()
    var mimes = newMimetypes()
    var outputTable = newStringTable(modeCaseSensitive)
    defer: httpClient.close()
    for pattern in args:
        for file in walkFiles(pattern):
            var data = newMultipartData()
            data.add({"username": username, "password": password, "output": "json"})
            data.addFiles({"file": file}, mimedb = mimes)
            var response = httpClient.postContent("https://lpix.org/api", multipart=data)
            var jsonNode = parseJson(response)
            if jsonNode.kind != JObject:
                echo "unexpected response for " & file & ": " & response
            elif jsonNode["err"].kind == JNull:
                let filename = jsonNode["filename"].getStr()
                if outputTable.contains(filename):
                    echo "outputTable already contains data for " & filename & ", outputting old value"
                    echo outputTable[filename]
                outputTable[filename] = jsonNode["imageUrl"].getStr() # TODO: Add error validation
            else:
                echo "upload of " & file & " failed with error code " & jsonNode["error"].getStr("??????")
    var outputStream = newFileStream(output, fmWrite)
    if outputStream == nil:
        echo "Unable to open output file " & output
        echo "Outputting string table to stdout: "
        echo $(outputTable.toJson)
    defer: outputStream.close()
    outputStream.write($(outputTable.toJson))

dispatch nimsend
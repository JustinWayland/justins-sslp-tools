import std/parsecfg
import std/paths
import std/appdirs
import std/streams
import std/strutils
import std/os
import std/[mimetypes, httpclient]
import cligen

type 
    MissingOptionException = object of ValueError

proc nimsend(args: seq[string]): int =
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
    try:
        for pattern in args:
            for file in walkPattern(pattern):
                var data = newMultipartData()
                data.add({"username": username, "password": password, "output": "json"})
                data.addFiles({"file": file}, mimedb = mimes)
                echo httpClient.postContent("https://lpix.org/api", multipart=data)
    finally:
        httpClient.close()
dispatch nimsend
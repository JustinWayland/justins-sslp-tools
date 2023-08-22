import std/parsecfg
import std/paths
import std/appdirs
import std/streams
import std/strutils

type 
    MissingOptionException = object of ValueError

let configPath: Path = getConfigDir() / Path("nimsend") / Path("nimsend.ini")
var configStream = newFileStream(configPath.string, fmRead)
assert configStream != nil, "can't read required configuration file " & configPath.string
try: 
    var settings: Config = loadConfig(configStream.Stream, configPath.string)
    let username = settings.getSectionValue("", "username", "")
    if username == "":
        raise newException(MissingOptionException, "username must be specified in the default section of the file")
    let password = settings.getSectionValue("", "password", "")
    if password == "":
        raise newException(MissingOptionException, "password must be specified in the default section of the file")
    let mb_limit = parseInt(settings.getSectionValue("", "mb_limit", "2"))
    echo "username: " & username
    echo "password: " & password
    echo "mb_limit: " & $mb_limit
finally:
    configStream.close()
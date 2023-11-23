set "scriptdir=%~dp0"
set "LogLocation=%scriptdir%"

DISM /Online /LogPath:"%scriptdir%ssu-19041.3562-x64_Install.log" /LogLevel:3  /Add-Package /PackagePath:"%scriptdir%ssu-19041.3562-x64_de23c91f483b2e609cec3e4a995639d13205f867.msu" /NoRestart
DISM /Online /LogPath:"%scriptdir%windows10.0-kb5031356-x64_Install.log" /LogLevel:3  /Add-Package /PackagePath:"%scriptdir%windows10.0-kb5031356-x64_65d5bbc39ccb461472d9854f1a370fe018b79fcc.msu" /NoRestart
DISM /Online /LogPath:"%scriptdir%windows10.0-kb5030841-x64-ndp48_Install.log" /LogLevel:3  /Add-Package /PackagePath:"%scriptdir%windows10.0-kb5030841-x64-ndp48_805cf05096bffae4a4f2ff13fa1aa6a888528bb5.msu" /NoRestart
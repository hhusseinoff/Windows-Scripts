net stop ccmexec
net stop bits
net stop msiserver
net stop wuauserv
net stop appidsvc
net stop cryptsvc
ipconfig /flushdns
Del %ALLUSERSPROFILE%\Microsoft\Network\Downloader\qmgr*.dat /Q
Del "%HOMEDRIVE%\Users\All Users\Microsoft\Network\Downloader\qmgr*.dat" /Q
Del "%HOMEDRIVE%\ProgramData\Microsoft\Network\Downloader\qmgr*.dat" /Q
Del %WINDIR%\SoftwareDistribution /s /Q
ren C:\Windows\System32\catroot2 catroot2.old
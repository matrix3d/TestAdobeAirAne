set FLEX="D:\sdk\AIRSDK_Compiler31"
call %FLEX%\bin\compc -load-config %FLEX%/frameworks/air-config.xml -sp swcsrc -include-sources swcsrc -swf-version=13 -o flashlua.swc
tar -x -f flashlua.swc
pause
set FLEX="D:\sdk\AIRSDK_Compiler31"
call %FLEX%\bin\adt.bat -package -storetype pkcs12 -keystore ..\bat\TestAdobeAirAneSWC.p12 -storepass fd -target ane ..\ext\flashlua.ane extension.xml -swc flashlua.swc -platform Windows-x86 library.swf luaas3api.dll -platform iPhone-ARM library.swf liblua.a
cd ../ext
mkdir _flashlua.ane
tar -x -f flashlua.ane -C _flashlua.ane
pause
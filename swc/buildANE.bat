set FLEX="D:\sdk\AIRSDK_Compiler31"
call %FLEX%\bin\adt.bat -package -storetype pkcs12 -keystore bat\TestAdobeAirAneSWC.p12 -storepass fd -target ane ext\winane.ane extension.xml -swc TestAdobeAirAne.swc -platform Windows-x86 library.swf hello.dll -platform iPhone-ARM library.swf hello.a
cd ext
mkdir _winane.ane
tar -x -f winane.ane -C _winane.ane
pause
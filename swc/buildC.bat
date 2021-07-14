set path=F:\MinGW\msys\1.0\bin;F:\MinGW\bin;%path%
cd csrc
gcc -c hello.c
gcc -shared -o ..\hello.dll hello.o FlashRuntimeExtensions.lib
cd ..
pause
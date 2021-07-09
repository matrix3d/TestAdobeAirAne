set path=%path%;F:\MinGW\bin
cd csrc
gcc -c hello.c
gcc -shared -o ..\hello.dll hello.o FlashRuntimeExtensions.lib
cd ..
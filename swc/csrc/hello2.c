/* hello.c */
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
void main(){
	 char* msg = ( char*)("hello");
	//msg[1]=100;
	char a[1];
	
	//sprintf(a,"%d",100);
	itoa(100,a,10);
	
	//msg[0]=a[0];
	//strcpy(msg,a);
	 
	printf(msg);
}
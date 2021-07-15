#include <string.h>
#include "FlashRuntimeExtensions.h"
#include <stdio.h>
#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#define EXPORT __declspec(dllexport)
void load(lua_State* L, int* w) {
    if (luaL_dostring(L,"i = 0 for j=0,10000000,1 do i=i+1 end")) {
        printf("Error Msg is %s.\n",lua_tostring(L,-1));
        return;
    }
    lua_getglobal(L,"i");
    *w = lua_tointeger(L,-1);
}

FREObject _hello(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
  FREObject ret;
  
  lua_State* L = luaL_newstate();
    int w;
    load(L,&w);
    lua_close(L);
  FRENewObjectFromInt32(w,&ret);
	//if(w>100){
 // const char* msg = (const char*)("Hello, Worldlua!");
  //FRENewObjectFromUTF8(strlen(msg) + 1, (const uint8_t*)msg, &ret);
	//}else{
	//	 const char* msg2 = (const char*)("Hello, World2lua!");
  //FRENewObjectFromUTF8(strlen(msg2) + 1, (const uint8_t*)msg2, &ret);
//	}
  
  return ret;
}


FREObject newState(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
  FREObject ret;
  lua_State* L = luaL_newstate();
  FRENewObjectFromInt32((int32_t)L,&ret);
  return ret;
}

FREObject dostring(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
  FREObject ret;
  lua_State* L;
  FREGetObjectAsInt32(argv[0],(int32_t*)&L);
  const char* s;
  uint32_t length;
  FREGetObjectAsUTF8(argv[1],&length,(const uint8_t**) &s);
  uint32_t b= luaL_dostring(L,s);
  FRENewObjectFromUint32(b,&ret);
  return ret;
}

FREObject getglobaltointeger(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
  FREObject ret;
  lua_State* L;
  FREGetObjectAsInt32(argv[0],(int32_t*)&L);
  const char* s;
  uint32_t length;
  FREGetObjectAsUTF8(argv[1],&length,(const uint8_t**) &s);
  lua_getglobal(L,s);
  int32_t i = lua_tointeger(L,-1);
  FRENewObjectFromUint32(i,&ret);
  return ret;
}

FRENamedFunction _methods[] = {
  { (const uint8_t*)"newState", NULL, newState },
  { (const uint8_t*)"dostring", NULL, dostring },
  { (const uint8_t*)"getglobaltointeger", NULL, getglobaltointeger }
};
void _ctxInitializer(void* extData, const uint8_t* ctxType,
                     FREContext ctx, uint32_t* numFunctionsToSet,
                     const FRENamedFunction** functionsToSet) {
  *numFunctionsToSet = sizeof(_methods)/sizeof(FRENamedFunction); // == 1
  *functionsToSet = _methods;
}
void _ctxFinalizer(FREContext ctx) {}

EXPORT void extInitializer(void** extDataToSet,
                           FREContextInitializer* ctxInitializerToSet,
                           FREContextFinalizer* ctxFinalizerToSet) {
  *extDataToSet = NULL; 
  *ctxInitializerToSet = _ctxInitializer; 
  *ctxFinalizerToSet = _ctxFinalizer; 
}

EXPORT void extFinalizer(void* extData) {}


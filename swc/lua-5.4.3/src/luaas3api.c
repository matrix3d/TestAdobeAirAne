#include <string.h>
#include "FlashRuntimeExtensions.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

FREObject newState(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
  FREObject ret;
  lua_State* L = luaL_newstate();
  FRENewObjectFromInt32((int32_t)L,&ret);
  return ret;
}
FREObject openlibs(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
					 
  //FREObject ret;
  lua_State* L;
  FREGetObjectAsInt32(argv[0],(int32_t*)&L);
 luaL_openlibs(L);
  return NULL;
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
  { (const uint8_t*)"openlibs", NULL, openlibs },
  { (const uint8_t*)"getglobaltointeger", NULL, getglobaltointeger }
};
void _ctxInitializer(void* extData, const uint8_t* ctxType,
                     FREContext ctx, uint32_t* numFunctionsToSet,
                     const FRENamedFunction** functionsToSet) {
  *numFunctionsToSet = sizeof(_methods)/sizeof(FRENamedFunction); // == 1
  *functionsToSet = _methods;
}
void _ctxFinalizer(FREContext ctx) {}

void extInitializer(void** extDataToSet,
                           FREContextInitializer* ctxInitializerToSet,
                           FREContextFinalizer* ctxFinalizerToSet) {
  *extDataToSet = NULL; 
  *ctxInitializerToSet = _ctxInitializer; 
  *ctxFinalizerToSet = _ctxFinalizer; 
}

void extFinalizer(void* extData) {}


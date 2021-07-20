#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"

// ===============================================================
//                    Flash Object Interop
// ===============================================================

static int flash_getprop (lua_State *L);
static int flash_setprop (lua_State *L);
static int flash_call (lua_State *L);
static int flash_apply (lua_State *L);

#define FlashObjectType "flash"
#define FlashObj unsigned int


static int FlashObj_gc(lua_State *L)
{
  //FlashObj *obj = getObjRef(L, 1);
  //inline_as3("trace(\"gc: \" + %0);\n" :  : "r"(obj));
  //lua_pop(L, 1);
  return 0;
}

static int FlashObj_tostring(lua_State *L)
{
  //FlashObj obj = getObjRef(L, 1);
  //char *str = NULL;
  //lua_pop(L, 1);
  //inline_as3("%0 = CModule.mallocString(\"\"+__lua_objrefs[%1]);\n" : "=r"(str) : "r"(obj));
  //lua_pushfstring(L, "%s", str);
  //free(str);
  return 1;
}

static const luaL_Reg FlashObj_meta[] = {
  {"__gc",        FlashObj_gc},
  {"__tostring",  FlashObj_tostring},
  {"__index",     flash_getprop},
  {"__newindex",  flash_setprop},
  {"__call",      flash_apply},
  {0, 0}
};

// ===============================================================
//                    Flash API Interop
// ===============================================================

static int flash_trace (lua_State *L) {
  //size_t l;
  //const char *s = luaL_checklstring(L, 1, &l);
  //AS3_DeclareVar(str, String);
  //AS3_CopyCStringToVar(str, s, l);
  //lua_pop(L, 1);
  //inline_nonreentrant_as3("trace(str);\n");
  return 1;
}

static int flash_getprop (lua_State *L) {
	return 1;
}

static int flash_setprop (lua_State *L) {
  return 1;
}

static int flash_apply (lua_State *L) {
  return 1;
}

// ===============================================================
//                          Registration
// ===============================================================

static const luaL_Reg flashlib[] = {
  {"trace", flash_trace},
  {NULL, NULL}
};

LUAMOD_API int luaopen_flash (lua_State *L) {
  luaL_newlib(L, flashlib);

  luaL_newmetatable(L, "flash");
  luaL_setfuncs(L, FlashObj_meta, 0);
  //lua_pushliteral(L, "__index");
  //lua_pushvalue(L, -3);
  //lua_rawset(L, -3);
  //lua_pushliteral(L, "__metatable");
  //lua_pushvalue(L, -3);
  //lua_rawset(L, -3);
  lua_pop(L, 1);

  return 1;
}
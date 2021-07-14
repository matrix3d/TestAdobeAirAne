/* hello.c 
https://www.cnblogs.com/orangeform/archive/2012/07/20/2460634.html
*/
#include <string.h>
#include "FlashRuntimeExtensions.h"
#include <stdio.h>
#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#define EXPORT __declspec(dllexport)

// ネイティブ関数の本体
// "Hello, World!" という文字列データをFREObject値として返す
FREObject _hello(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
  FREObject ret;
  
  //lua_State* L = luaL_newstate();
    //int w,h;
    //load(L,&w,&h);
    //lua_close(L);
  
	//if(w>100){
  const char* msg = (const char*)("Hello, Worldlua!");
  FRENewObjectFromUTF8(strlen(msg) + 1, (const uint8_t*)msg, &ret);
	//}else{
	//	 const char* msg2 = (const char*)("Hello, World2lua!");
  //FRENewObjectFromUTF8(strlen(msg2) + 1, (const uint8_t*)msg2, &ret);
//	}
  
  return ret;
}



/** FREObject型
 *    typedef void* FREObject
 *
 ** FRENewObjectFromUTF8関数
 *    FREResult FRENewObjectFromUTF8(uint32_t        length,
 *                                   const uint8_t*  value ,
 *                                   FREObject*      object);
 */

// 関数テーブル
// "hello" がAIRランタイム側(AS)から呼び出される関数名
// functionData はここでは使わない
// _hello がネイティブ関数へのポインタ
FRENamedFunction _methods[] = {
  { (const uint8_t*)"hello", NULL, _hello }
};
/** FRENamedFunction構造体
 *     typedef struct FRENamedFunction_ {
 *       const uint8_t* name;
 *       void*          functionData;
 *       FREFunction    function;
 *     } FRENamedFunction;
 */

// 拡張コンテキスト初期化時に呼ばれる
void _ctxInitializer(void* extData, const uint8_t* ctxType,
                     FREContext ctx, uint32_t* numFunctionsToSet,
                     const FRENamedFunction** functionsToSet) {
  *numFunctionsToSet = sizeof(_methods)/sizeof(FRENamedFunction); // == 1
  *functionsToSet = _methods; // 関数テーブルの紐付け
}


// 拡張コンテキスト破棄時に呼ばれる
void _ctxFinalizer(FREContext ctx) { /* なにもしない */}

// アプリケーション初期化時に呼ばれる, DLLからエクスポート
EXPORT void extInitializer(void** extDataToSet,
                           FREContextInitializer* ctxInitializerToSet,
                           FREContextFinalizer* ctxFinalizerToSet) {
  *extDataToSet = NULL;  // 拡張データ, ここでは使わない
  *ctxInitializerToSet = _ctxInitializer; // イニシャライザの紐付け
  *ctxFinalizerToSet = _ctxFinalizer;     // ファイナライザの紐付け
}

// アプリケーション終了時に呼ばれる, DLLからエクスポート
EXPORT void extFinalizer(void* extData) { /* なにもしない */ }

void load(lua_State* L, int* w, int* h) {
    if (luaL_loadstring(L,"width = 200 height = 300") || lua_pcall(L,0,0,0)) {
        printf("Error Msg is %s.\n",lua_tostring(L,-1));
        return;
    }
    lua_getglobal(L,"width");
    lua_getglobal(L,"height");
    if (!lua_isnumber(L,-2)) {
        printf("'width' should be a number\n" );
        return;
    }
    if (!lua_isnumber(L,-1)) {
        printf("'height' should be a number\n" );
        return;
    }
    *w = lua_tointeger(L,-2);
    *h = lua_tointeger(L,-1);
}
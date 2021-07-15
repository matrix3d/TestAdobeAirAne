/* hello.c */
#include <string.h>
#include "FlashRuntimeExtensions.h"
//#define EXPORT __declspec(dllexport)

// ネイティブ関数の本体
// "Hello, World!" という文字列データをFREObject値として返す
FREObject _hello(FREObject ctx, void* funcData,
                 uint32_t argc, FREObject argv[]) {
  FREObject ret;
  //const char* msg = (const char*)"Hello, World!";
  //FRENewObjectFromUTF8(strlen(msg) + 1, (const uint8_t*)msg, &ret);
  int32_t j=0;
  for(int32_t i=0;i<=10000000;i++){
	  j++;
	}
  FRENewObjectFromInt32(j,&ret);
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
void extInitializer(void** extDataToSet,
                           FREContextInitializer* ctxInitializerToSet,
                           FREContextFinalizer* ctxFinalizerToSet) {
  *extDataToSet = NULL;  // 拡張データ, ここでは使わない
  *ctxInitializerToSet = _ctxInitializer; // イニシャライザの紐付け
  *ctxFinalizerToSet = _ctxFinalizer;     // ファイナライザの紐付け
}

// アプリケーション終了時に呼ばれる, DLLからエクスポート
//EXPORT void extFinalizer(void* extData) { /* なにもしない */ }
package parser
{
   import Module.fuben.DuorenTeamInfoView;
   import flash.system.ApplicationDomain;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.getDefinitionByName;
   import flash.display.Sprite;
   import flash.utils.getQualifiedClassName;
   import parse.ProxyFunc;
   import flash.net.URLLoader;
   import flash.events.Event;
   import flash.net.URLRequest;
   import parse.Lex;
   import util.ASC;
   
   public class Script
   {
      
	  public static var ____globalclass:GenTree;
      
	  public  static var __globaldy:parser.DY;
      
      public static var vm:parser.DY;
      
      static var output:Function;
      
      public static var classes:Object = {};
      
      static var errores:Object = {};
      
      static var Debug;
      
      static var app:ApplicationDomain;
      
      public static var defaults:Object = {};
      
      public static var _root:Sprite;
      
      public static var scriptdir:String = "script/";
	  public static var ascs:Object;
	  public static var scripts:Object;
	  public static var optimize:Boolean = false;
       
      public function Script()
      {
         super();
      }
      public static var globalAPI:Object={};
      public static function addAPI(Aname:String, api:*) : void
      {
         globalAPI[Aname] = api;
      }
      public static function dispose():void{
		  defaults = {};
		  classes = {};
		  ascs = {};
		  GenTree.staticBranch = {};
		  ProxyFunc.dics = new Dictionary();
		 // scripts = {};
		  errores = {};
	  }
      public static function getDef(clname:String) : *
      {
         var c:* = undefined;
         if(!classes[clname])
         {
            if(!errores[clname])
            {
               try
               {
                  c = getDefinitionByName(clname);
                  if(c)
                  {
                     classes[clname] = c;
                  }
                  return c;
               }
               catch(e:*)
               {
                  errores[clname] = true;
               }
            }
            if(app.hasDefinition(clname))
            {
               classes[clname] = app.getDefinition(clname);
            }
         }
         return classes[clname];
      }
      
      static function set root(r:Sprite) : void
      {
         _root = r;
         app = r.loaderInfo.applicationDomain;
		 CONFIG::debug{
		 r.addEventListener(Event.ENTER_FRAME, r_enterFrame);
		 }
      }
	  
	  static private function r_enterFrame(e:Event):void 
	  {
		  DY.stacks = [];
	  }
      
      public static function init(__root:Sprite, code:String = null) : void
      {
         root = __root;
         parser.DY.prototype.toString = function():String
         {
            return "这是一个脚本类";
         };
		 //
		 Script.addAPI("Number",parseFloat);
         Script.addAPI("int", function(v:Object):int{return int(v)});
		 Script.addAPI("Boolean", function(v:Object):Boolean{return Boolean(v)});
         Script.addAPI("String",function(v:Object):String{return String(v)});
         Script.addAPI("parseInt",parseInt);
         Script.addAPI("parseFloat", parseFloat);
		 Script.addAPI("isNaN", isNaN);
		 Script.addAPI("isXMLName", isXMLName);
		 Script.addAPI("trace", trace);
		 Script.addAPI("decodeURI", decodeURI);
		 Script.addAPI("decodeURIComponent", decodeURIComponent);
		 Script.addAPI("encodeURI", encodeURI);
		 Script.addAPI("encodeURIComponent", encodeURIComponent);
		 Script.addAPI("getQualifiedClassName", getQualifiedClassName);
		 
		 Script.addAPI("typeof", function(v:Object):Object{return typeof(v); });
		Script.addAPI("trace", function(...args):void{
			CONFIG::debug{
				/*var linedepth:int =-1;
				for (var i:int = DY.stacks.length - 1; i >= 0;i-- ){
					var n:GNode = DY.stacks[i] as GNode;
					var dy:DY = DY.stacks[i] as DY;
					if (n&&n.linedepth!=-1){
						linedepth = n.linedepth;
						break;
					}
				}
				
				var lineFunName:int =-1;
				for (var i:int = DY.stacks.length - 1; i >= 0;i-- ){
					var n:GNode = DY.stacks[i] as GNode;
					if (n.linedepth!=-1){
						linedepth = n.linedepth;
						break;
					}
				}*/
				
				trace("[scriptTrace]",args)
			}
		});
		
		 Script.addAPI("__AS3__.vec.Vector.<int>", function(v:Object):Object{return Vector.<int>(v); });
		 Script.addAPI("__AS3__.vec.Vector.<uint>", function(v:Object):Object{return Vector.<uint>(v); });
		 Script.addAPI("__AS3__.vec.Vector.<Number>", function(v:Object):Object{return Vector.<Number>(v); });
		 Script.addAPI("__AS3__.vec.Vector.<Object>", function(v:Object):Object{return Vector.<Object>(v); });
		 CONFIG::debug{
		 Script.addAPI("__break", function(...args):void{
			 trace("__break");
		 });
		 }
		 
         if(code)
         {
            ____globalclass = LoadFromString(code,null);
            GenTree.Branch["____globalclass"] = ____globalclass;
         }
         else
         {
            ____globalclass = newScript("____globalclass");
         }
         __globaldy = New("____globalclass");
         vm = __globaldy;
		
	  }
      
      public static function LoadFromString(code:String,asname:String) : *
      {
         code = trim(code);
         return GenTree.create(code,asname);
      }
	  
	  public static function trim(code:String):String{
		  code = code.replace(/public\s/g,"");
         code = code.replace(/private\s/g, "");
         code = code.replace(/protected\s/g, "");
		 code = code.replace(/override\s/g, "");
		 code = code.replace(/dynamic\s/g, "");
		 return code;
	  }
	  
	  public static function LoadFromObj(obj:Object):*{
		  var b:ByteArray = obj as ByteArray;
		  if (b){
			  b.position = 0;
			  obj = b.readObject();
		  }
		  
		  var A:GenTree = ASC.decode(obj);
		  GenTree.Branch[A.name] = A;
		  return GenTree.createWithGenTree(A);
	  }
      
      public static function getFunc(funcname:String) : Function
      {
         return ProxyFunc.getAFunc(__globaldy,funcname);
      }
      
      private static function LoadFromFile(code:String) : void
      {
         var ld:URLLoader = new URLLoader();
         ld.addEventListener(Event.COMPLETE,onloadFile);
         ld.load(new URLRequest(code));
      }
      
      private static function onloadFile(e:Event) : void
      {
         LoadFromString((e.target as URLLoader).data,null);
      }
      
      private static function newScript(_name:String) : *
      {
         var mycode:String = "class " + _name + "{}";
         return GenTree.create(mycode);
      }
      
      public static function New(... args) : DY
      {
         var _name:String = null;
         if(args.length == 0)
         {
            _name = "__DY";
         }
         else
         {
            _name = args.shift();
         }
         if(GenTree.hasScript(_name))
         {
            return new parser.DY(GenTree.Branch[_name],args);
         }
         return new parser.DY(GenTree.Branch[_name],args);
      }
	  
	  public static function NewWithBase(... args) : *
      {
         var _name:String = null;
         if(args.length == 0)
         {
            _name = "__DY";
         }
         else
         {
            _name = args.shift();
         }
		 
		 var base:Object = args.shift();
		 
         if(GenTree.hasScript(_name))
         {
            return new parser.DY(GenTree.Branch[_name],args,base);
         }
         return new parser.DY(GenTree.Branch[_name],args,base);
      }
      
      /*public static function declare(code:String, clname:String = "____globalclass") : *
      {
         var lex:Lex = null;
         var cnode:GNode = null;
         if(GenTree.hasScript(clname))
         {
            lex = new Lex(code);
            cnode = (GenTree.Branch[clname] as GenTree).declares(lex);
            return __globaldy.executeST(cnode);
         }
      }
      
      public static function eval(code:String, ... args) : *
      {
         var cnode:GNode = null;
         var lex:Lex = null;
         if(args && args.length > 0)
         {
            code = "function __niming(args){return " + code + ";}";
            if(Lex.treecach[code])
            {
               cnode = Lex.treecach[code];
               ____globalclass.motheds[cnode.name] = cnode;
            }
            else
            {
               lex = new Lex(code);
               cnode = ____globalclass.declare(lex);
               Lex.treecach[code] = cnode;
            }
            return __globaldy.call("__niming",[args]);
         }
         code = "return " + code + ";";
         if(Lex.treecach[code])
         {
            cnode = Lex.treecach[code];
         }
         else
         {
            lex = new Lex(code);
            cnode = ____globalclass.declare(lex);
            Lex.treecach[code] = cnode;
         }
         return __globaldy.executeST(cnode);
      }*/
      
      /*public static function execute(code:String, ... args) : *
      {
         var cnode:GNode = null;
         var lex:Lex = null;
         if(Boolean(args) && args.length > 0)
         {
            code = "function __niming(args){" + code + "}";
            if(Lex.treecach[code])
            {
               cnode = Lex.treecach[code];
               ____globalclass.motheds[cnode.name] = cnode;
            }
            else
            {
               lex = new Lex(code);
               cnode = ____globalclass.declare(lex);
               Lex.treecach[code] = cnode;
            }
            return __globaldy.call("__niming",[args]);
         }
         if(Lex.treecach[code])
         {
            cnode = Lex.treecach[code];
         }
         else
         {
            lex = new Lex(code);
            cnode = ____globalclass.declares(lex);
            Lex.treecach[code] = cnode;
         }
         return __globaldy.executeST(cnode);
      }*/
      
     /* public static function decode(str:String) : *
      {
         var cnode:GNode = null;
         var code:String = "return " + str + ";";
         var lex:Lex = new Lex(code,true);
         cnode = ____globalclass.declare(lex);
         return __globaldy.executeST(cnode);
      }*/
      
      private static function encodeObj(ob:Object) : String
      {
         var o:* = null;
         if(ob == null)
         {
            return "null";
         }
         if(ob is String)
         {
            return escapeString(ob as String);
         }
         if(ob is Number)
         {
            return ob + "";
         }
         if(ob is Boolean)
         {
            return ob.toString();
         }
         var str:String = "{";
         for(o in ob)
         {
            str = str + (o + ":" + encode(ob[o]) + ",");
         }
         if(str.charAt(str.length - 1) == ",")
         {
            return str.substr(0,str.length - 1) + "}";
         }
         return "{}";
      }
      
      private static function escapeString(str:String) : String
      {
         var ch:String = null;
         var s:String = "";
         var len:Number = str.length;
         for(var i:int = 0; i < len; i++)
         {
            ch = str.charAt(i);
            switch(ch)
            {
               case "\"":
                  s = s + "\\\"";
                  break;
               case "\\":
                  s = s + "\\\\";
                  break;
               case "\b":
                  s = s + "\\b";
                  break;
               case "\f":
                  s = s + "\\f";
                  break;
               case "\n":
                  s = s + "\\n";
                  break;
               case "\r":
                  s = s + "\\r";
                  break;
               case "\t":
                  s = s + "\\t";
                  break;
               default:
                  s = s + ch;
            }
         }
         return "\"" + s + "\"";
      }
      public static function getStaticFunc(clname:String, funcname:String) {
		 if (GenTree.staticBranch[clname]) {
			 return (GenTree.staticBranch[clname].instance as DY)[funcname];
		 } 
		 return null;
	  }
      private static function encodeArr(ar:Array) : String
      {
         var str:String = "[";
         for(var i:int = 0; i < ar.length; i++)
         {
            if(ar[i] == null)
            {
               str = str + ",";
            }
            else if(ar[i] is Array)
            {
               str = str + (encodeArr(ar[i]) + ",");
            }
            else
            {
               str = str + (encodeObj(ar[i]) + ",");
            }
         }
         if(str.charAt(str.length - 1) == ",")
         {
            return str.substr(0,str.length - 1) + "]";
         }
         return "[]";
      }
      
      public static function encode(ob:Object) : *
      {
         var str:String = "";
         if(ob is Array)
         {
            return encodeArr(ob as Array);
         }
         return encodeObj(ob);
      }
   }
}

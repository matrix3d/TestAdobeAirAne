package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import parser.DY;
	import parser.Script;
	import sample.lua.CModule;
	
	/**
	 * ...
	 * @author lizhi
	 */
	public class Main extends Sprite 
	{
		
		public var luastate:int
		private  var tf:TextField;
		private var main;
		public function Main() 
		{
			tf = new TextField;
			tf.defaultTextFormat = new TextFormat(null, 24);
			tf.mouseEnabled = tf.mouseWheelEnabled = false;
			
			addChild(tf);
			CModule.startAsync(this);
			
			Script.init(this);
			var mainClass:String=(<![CDATA[
package
{
	public class HelloTriangleColored
	{
		public function a():int 
		{
			var i:int = 0;
				for (var j:int = 0; j <= 10000;j++ ){
					i++;
				}
				return i;
		}
	}
}
			]]>).toString();
			var obj:Object = Script.LoadFromString(mainClass,null);
			main = Script.New(obj.name);
			
			
			if (stage){
				addedToStage(null);
			}else{
				addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			}
		}
		
		private function addedToStage(e:Event):void 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			tf.width = stage.stageWidth;
			tf.height = stage.stageHeight;
			stage.addEventListener(MouseEvent.CLICK, stage_click);
			
			
			// Initialize Lua and load our script
			var err:int = 0
			luastate = Lua.luaL_newstate()
			Lua.lua_atpanic(luastate, atPanic)
			Lua.luaL_openlibs(luastate)
			var luascript:String = "function a() local time2 = os.time()  local i = 0 for j=0,10000000,1 do i=i+1 end time2 = os.time()-time2 flash.trace(time2) return i end";
			err = Lua.luaL_loadstring(luastate, luascript)
			if(err) {
				trace("Error " + err + ": " + Lua.luaL_checklstring(luastate, 1, 0))
				Lua.lua_close(luastate)
				return
			}
			err = Lua.lua_pcallk(luastate, 0, Lua.LUA_MULTRET, 0, 0, null)
			stage_click(null);
		}
		
		private function stage_click(e:MouseEvent):void 
		{

			try {
				sample.lua.__lua_objrefs = new Dictionary()

				var t:uint = getTimer();
				Lua.lua_getglobal(luastate, "a")
				Lua.lua_callk(luastate, 0, 1, 0, null)
				trace("LUA",Lua.lua_tonumberx(luastate, -1, 0), getTimer() - t);
				
				t = getTimer();
				var i:int = 0;
				for (var j:int = 0; j <= 10000000;j++ ){
					i++;
				}
				trace("AS3", i, getTimer() - t);
				
				t = getTimer();
				trace("ASC",main.a(), getTimer() - t);
			} catch(e:*) {
				trace("Exception thrown while initializing code:\n" + e);
			}
		}
		public function atPanic(e:*): void
        {
        	trace("Lua Panic: " + Lua.luaL_checklstring(luastate, -1, 0))
        }
		
		private function trace(...args):void{
			tf.appendText(args + "\n");
			tf.scrollV = tf.maxScrollV;
		}
		
	}
	
}
package
{
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import sample.lua.CModule;
	
	/**
	 * ...
	 * @author lizhi
	 */
	public class Main extends Sprite 
	{
		
		public var luastate:int
		public function Main() 
		{
			CModule.startAsync(this)
			// Initialize Lua and load our script
			var err:int = 0
			luastate = Lua.luaL_newstate()
			Lua.lua_atpanic(luastate, atPanic)
			Lua.luaL_openlibs(luastate)
			var luascript:String = "function a() local time2 = os.time()  local i = 0 for j=0,1000000000,1 do i=i+1 end time2 = os.time()-time2 flash.trace(time2) return i end";
			err = Lua.luaL_loadstring(luastate, luascript)
			if(err) {
				trace("Error " + err + ": " + Lua.luaL_checklstring(luastate, 1, 0))
				Lua.lua_close(luastate)
				return
			}

			try {
				sample.lua.__lua_objrefs = new Dictionary()

				// This runs everything in the global scope
				err = Lua.lua_pcallk(luastate, 0, Lua.LUA_MULTRET, 0, 0, null)
				
				var t:uint = getTimer();
				Lua.lua_getglobal(luastate, "a")
				Lua.lua_callk(luastate, 0, 1, 0, null)
				trace("LUA",Lua.lua_tonumberx(luastate, -1, 0), getTimer() - t);
				
				t = getTimer();
				var i:int = 0;
				for (var j:int = 0; j <= 1000000000;j++ ){
					i++;
				}
				trace("AS3",i, getTimer() - t);
			} catch(e:*) {
				trace("Exception thrown while initializing code:\n" + e);
			}
		}
		public function atPanic(e:*): void
        {
        	trace("Lua Panic: " + Lua.luaL_checklstring(luastate, -1, 0))
        }
		
	}
	
}
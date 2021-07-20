package  
{
	import com.bit101.components.HBox;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import com.bit101.components.Style;
	import com.bit101.components.TextArea;
	import com.bit101.components.VBox;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import sample.lua.CModule;
            import sample.lua.vfs.ISpecialFile;
            import flash.utils.ByteArray;
            import flash.utils.getTimer;
            import mx.controls.Alert;
            import Lua;
	/**
	 * ...
	 * @author lizhi
	 */
	public class LuaTest extends Sprite
	{
		private var inbox:TextArea;
		private var runtimelabel:Label;
		private var outbox:TextArea;
		internal var luastate:int;
		public function LuaTest() 
		{
			Style.embedFonts = false;
			Style.fontSize = 12;
			Style.fontName = "宋体";
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			var vb:VBox= new VBox(this);
			inbox = new TextArea(vb);
			var hb:HBox = new HBox(vb);
			new PushButton(hb,0,0, "Run Script", runScript);
			runtimelabel = new Label(hb);
			outbox = new TextArea(vb);
			
			appInit(null);
		}
		
		internal function appInit(event:Event):void
            {
                CModule.rootSprite = this
                //CModule.vfs.console = this
                CModule.startAsync(this)

                runScript(null)
            }

            internal function runScript(event:Event):void
            {
                var err:int = 0
                outbox.text = ""
                luastate = Lua.luaL_newstate()
                
                Lua.luaL_openlibs(luastate)
                err = Lua.luaL_loadstring(luastate, inbox.text)
                if(err) {
                    Lua.lua_settop(luastate, -2)
                    Lua.lua_close(luastate)
                    output("Can't parse script: " + err)
                    return
                }

                var runtime:int = getTimer()
                err = Lua.lua_pcallk(luastate, 0, Lua.LUA_MULTRET, 0, 0, null)
                runtime = getTimer() - runtime
                runtimelabel.text = "Script time: " + runtime + "ms" /* + " final stack depth: " + Lua.lua_gettop(luastate) */

                if (err) {
                    output("Failed to run script: " +  Lua.lua_tolstring(luastate, -1, 0))
                } else {
                    var result:Number = Lua.lua_tonumberx(luastate, -1, 0)
                    output("Script returned: " + result)
                }

                Lua.lua_settop(luastate, -2)
                Lua.lua_close(luastate)
            }

            public function output(s:String):void
            {
                outbox.text += s
                trace( s )
            }

            /**
            * The PlayerKernel implementation will use this function to handle
            * C IO write requests to the file "/dev/tty" (e.g. output from
            * printf will pass through this function). See the ISpecialFile
            * documentation for more information about the arguments and return value.
            */
            public function write(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int
            {
              var str:String = CModule.readString(bufPtr, nbyte)
              output(str)
              return nbyte
            }

            /**
            * The PlayerKernel implementation will use this function to handle
            * C IO read requests to the file "/dev/tty" (e.g. reads from stdin
            * will expect this function to provide the data). See the ISpecialFile
            * documentation for more information about the arguments and return value.
            */
            public function read(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int
            {
              return 0
            }

            /**
            * The PlayerKernel implementation will use this function to handle
            * C fcntl requests to the file "/dev/tty" 
            * See the ISpecialFile documentation for more information about the
            * arguments and return value.
            */
            public function fcntl(fd:int, com:int, data:int, errnoPtr:int):int
            {
              return 0
            }

            /**
            * The PlayerKernel implementation will use this function to handle
            * C ioctl requests to the file "/dev/tty" 
            * See the ISpecialFile documentation for more information about the
            * arguments and return value.
            */
            public function ioctl(fd:int, com:int, data:int, errnoPtr:int):int
            {
              return 0;
            }
		
	}

}
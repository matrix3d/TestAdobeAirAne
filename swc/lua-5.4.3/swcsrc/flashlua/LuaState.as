package flashlua 
{
	/**
	 * ...
	 * @author lizhi
	 */
	public class LuaState extends LuaBase
	{
		
		public function LuaState() 
		{
			
		}
		
		public function dostring(s:String):uint{
			return LuaAPI.context.call("dostring",pointer,s) as uint;
		}
		
		public function getglobaltointeger(name:String):int{
			return LuaAPI.context.call("getglobaltointeger",pointer,name) as uint;
		}
		public function openlibs():void{
			LuaAPI.context.call("openlibs", pointer);
		}
	}

}
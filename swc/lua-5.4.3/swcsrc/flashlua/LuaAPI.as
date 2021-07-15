package flashlua
{
	import flash.external.ExtensionContext;
	
	/**
	 * ...
	 * @author lizhi
	 */
	public class LuaAPI
	{
		public static var context:ExtensionContext;
		
		public static function Init():void
		{
			context= ExtensionContext.createExtensionContext("luaane", ""); 
		}
		public static function NewState():LuaState
		{
			var state:LuaState = new LuaState;
			state.pointer=context.call("newState") as int;
			return state;
		}
	}
	
}
package  
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	import flashlua.LuaAPI;
	import flashlua.LuaState;
	/**
	 * ...
	 * @author lizhi
	 */
	public class Main extends Sprite
	{
		private var test:TestAdobeAirAneSWC;
		
		public function Main() 
		{
			
			test = new TestAdobeAirAneSWC();
			stage.addEventListener(MouseEvent.CLICK, stage_click);
			
			LuaAPI.Init();
		}
		
		private function stage_click(e:MouseEvent):void 
		{
			var state:LuaState = LuaAPI.NewState();
			var t:int = getTimer();
			trace(state.dostring("i = 0 k=100 h=101 for j=0,10000000,1 do i=i+1 end"));
			trace(state.getglobaltointeger("i"), state.getglobaltointeger("k"), state.getglobaltointeger("h"));
			trace(getTimer()-t,"ms");
		}
		
	}

}
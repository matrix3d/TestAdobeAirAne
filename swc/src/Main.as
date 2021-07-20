package  
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
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
		private  var tf:TextField;
		public function Main() 
		{
			tf = new TextField;
			tf.defaultTextFormat = new TextFormat(null, 24);
			tf.mouseEnabled = tf.mouseWheelEnabled = false;
			
			addChild(tf);
			
			//var a:Object = {trace:trace};
			// a.trace(1212312);
			
			test = new TestAdobeAirAneSWC();
			var aaa:Object = test.trace();
			/*trace("trace",
			test.trace());*/
			
			LuaAPI.Init();
			
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
			stage_click(null);
		}
		
		private function stage_click(e:MouseEvent):void 
		{
			var time:int = getTimer();
			//trace(test.test() + " clang0,"+(getTimer()-time)+",ms");
			var state:LuaState = LuaAPI.NewState();
			state.openlibs();
			trace(state.pointer);
			var t:int = getTimer();
			trace(state.dostring("i = 0 k=100 h=trace() for j=0,10000000,1 do i=i+1 end"));
			trace(state.getglobaltointeger("i"), state.getglobaltointeger("k"), state.getglobaltointeger("h"));
			trace(getTimer() - t, "ms");
			
			
		}
		private function trace(...args):void{
			tf.appendText(args + "\n");
			tf.scrollV = tf.maxScrollV;
		}
		
	}

}
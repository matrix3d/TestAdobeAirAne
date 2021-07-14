package  
{
	import flash.display.Sprite;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author lizhi
	 */
	public class Main extends Sprite
	{
		
		public function Main() 
		{
			var t:int = getTimer();
			var test:TestAdobeAirAneSWC = new TestAdobeAirAneSWC();
			trace(test.test(),getTimer()-t);
			//trace(test.test2(2));
		}
		
	}

}
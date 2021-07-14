package test 
{
	import flash.display.Sprite;
	import parser.GNode;
	/**
	 * ...
	 * @author lizhi
	 */
	public class TestMem extends Sprite
	{
		private static var mem:Array = [];
		public function TestMem() 
		{
			for (var i = 0; i < 1000000;i++ ){
				mem.push(new GNode);
			}
		}
		
	}

}
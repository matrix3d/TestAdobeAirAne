package
{
	import flash.external.ExtensionContext;
	
	/**
	 * ...
	 * @author lizhi
	 */
	public class TestAdobeAirAneSWC
	{
		private var context:ExtensionContext;
		
		public function TestAdobeAirAneSWC() 
		{
			context= ExtensionContext.createExtensionContext("winane", ""); 
		}
		public function test():int
		{
			return context.call("hello") as int;
		}
		
		public function trace():Object{
			return context.call("trace", new A/*{Trace:trace}*/);
		}
		
	}
	
}
class A{
	public function Trace(...args):void{
		trace("ATR",args);
	}
}
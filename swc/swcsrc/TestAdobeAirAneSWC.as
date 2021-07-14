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
		
		public function test2(v:int):int{
			return context.call("test2", v) as int;
		}
		
	}
	
}
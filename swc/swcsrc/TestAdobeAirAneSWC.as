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
		public function test():String
		{
			return context.call("hello") as String;
		} 
		
	}
	
}
package parse
{
	import avmplus.DescribeTypeJSON;
   public class TokenType
   {
      
      public static const ident:int = 1;//""
      public static const config:int = 102;//""
      
      public static const constant:int = 2;//""
      
      public static const Assign:int = 3;//""
      
      public static const MOP:int = 4;//""
      
      public static const LOP:int = 5;//""
      
      public static const COP:int = 6;//""
      
      public static const INCREMENT:int = 7;//""
      
      public static const LOPNot:int = 40;//""
      
      public static const keyclass:int = 10;//""
      
      public static const keyimport:int = 11;//""
      
      public static const keyfunction:int = 12;//""
      
	  public static const keystatic:int = 57;//""
	  
      public static const keyif:int = 13;//""
      
      public static const keyelse:int = 14;//""
      
      public static const keyfor:int = 15;//""
      
      public static const keywhile:int = 16;//""
      
      public static const keyvar:int = 17;//""
      
      public static const keyreturn:int = 18;//""
      
      public static const keynew:int = 19;//""
      
      public static const keyextends:int = 20;//""
      public static const keyimplements:int = 101;//""
	  
      public static const keypackage:int = 42;//""
      
      public static const keypublic:int = 44;//""
      public static const keydynamic:int = 103;//""
      
      public static const keyprivate:int = 45;//""
      
      public static const keyprotected:int = 46;//""
      
      public static const keyswitch:int = 47;//""
      
      public static const keycase:int = 48;//""
      
      public static const keybreak:int = 49;//""
      
      public static const keydefault:int = 50;//""
      
      public static const keycontinue:int = 51;//""
      
      public static const keytry:int = 52;//""
      
      public static const keycatch:int = 53;//""
      
      public static const keyfinally:int = 54;//""
      
      public static const keyeach:int = 55;//""
      
      public static const LBRACE:int = 21;//""
      
      public static const RBRACE:int = 22;//""
      
      public static const LParent:int = 23;//""
      
      public static const RParent:int = 24;//""
      
      public static const DOT:int = 25;//""
      
      public static const COMMA:int = 26;//""
      
      public static const Semicolon:int = 27;//""
      
      public static const NULL:int = 29;//""
      
      public static const LBRACKET:int = 30;//""
      
      public static const RBRACKET:int = 31;//""
      
      public static const Colon:int = 100;//""
	  
      public static const Question:int = 33;//""
	  
	  /*public static var keyget:int = 10000;
	  public static var keyset:int = 10001;*/
       
      public var id:int;
       private static var names:Object;
      public function TokenType(_id:int = 0)
      {
         super();
         this.id = _id;
      }
	  
	   public static function getName(i:int) : String
      {
		  if (names == null){
			  names = {};
			  var dj:DescribeTypeJSON = new DescribeTypeJSON;
			var obj:Object = dj.getClassDescription(TokenType);
			for each(var a:Object in obj.traits.variables){
				if (a.type == "int"){
					var v:int=TokenType[a.name]
					names[v] = a.name;
				}
			}
		  }
		/*var dj:DescribeTypeJSON = new  DescribeTypeJSON;
		var a= dj.describeType(GNodeType, DescribeTypeJSON.CLASS_FLAGS);*/
         return names[i];
      }
   }
}

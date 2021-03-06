package parse
{
   public class Token
   {
      
      public static var wordpatten:String = "|const|static|as|is|instanceof|extends|implements|in|package|for|var|new|class|function|if|else|while|return|import|public|private|protected|dynamic|switch|case|break|continue|default|try|catch|finally|each|";
       
      public var type:int;
      
      public var value;
      
      public var word:String;
      
	  
	  CONFIG::debug{
      public var line:int = 0;
      
      var linestr:String = "";
      public var index:int;
      }
      
	  
      public function Token()
      {
         super();
      }
      
      public static function iskeyword(str:String) : Boolean
      {
         if(Token.wordpatten.indexOf("|" + str + "|") >= 0)
         {
            return true;
         }
         return false;
      }
      
      public static function getTypeName(str:String) : String
      {
         if(iskeyword(str))
         {
            return "TokenType.key" + str;
         }
         return "TokenType." + getDec(str);
      }
      
      public static function getDec(str:String) : String
      {
         if(str == "(")
         {
            return "LParent";
         }
         if(str == ")")
         {
            return "RParent";
         }
         if(str == "{")
         {
            return "LBRACE";
         }
         if(str == "}")
         {
            return "RBRACE";
         }
         if(str == "[")
         {
            return "LBRACKET";
         }
         if(str == "]")
         {
            return "RBRACKET";
         }
         if(str == ".")
         {
            return "DOT";
         }
         if(str == ",")
         {
            return "COMMA";
         }
         if(str == ";")
         {
            return "Semicolon";
         }
         if(str == ":")
         {
            return "Colon";
         }
         return str;
      }
      
	  CONFIG::debug
      public function getLine() : String
      {
         return this.linestr;
      }
	  
	  public function toString():String{
		  return type+":" + value;
	  }
	  
	  public function get tokenTypeName(): String { 
			return  TokenType.getName(type);
		}
   }
}

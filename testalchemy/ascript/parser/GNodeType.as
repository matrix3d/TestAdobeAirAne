package parser
{
	import avmplus.DescribeTypeJSON;
   public class GNodeType
   {
      
      public static const CLASS:int = 20;
      
      public static const FunDecl:int = 0;
      
      public static const VarDecl:int = 1;
      
      public static const Params:int = 2;
      
      public static const MOP:int = 3;
      
      public static const LOP:int = 4;
      
      public static const LOPNot:int = 22;
      
      public static const Nagtive:int = 23;
      
      public static const COP:int = 5;
      
      public static const Stms:int = 6;
      
      public static const AssignStm:int = 7;
      
      public static const IfElseStm:int = 8;
      
      public static const WhileStm:int = 9;
      
      public static const ForStm:int = 10;
      
      public static const ForInStm:int = 25;
      
      public static const ForEACHStm:int = 40;
      
      public static const ReturnStm:int = 11;
      
      public static const FunCall:int = 12;
      
      public static const VarID:int = 13;
      
      public static const IDENT:int = 24;
      
      public static const Index:int = 28;
      
      public static const SWITCH:int = 29;
      
      public static const CASE:int = 30;
      
      public static const DEFAULT:int = 31;
      
      public static const TRY:int = 32;
      
      public static const CATCH:int = 33;
      
      public static const FINALLY:int = 34;
      
      public static const BREAK:int = 35;
      
      public static const CONTINUE:int = 36;
      
      public static const ELSEIF:int = 37;
      
      public static const PREINCREMENT:int = 38;
      
      public static const INCREMENT:int = 39;
      
      public static const newArray:int = 26;
      
      public static const newObject:int = 27;
      
      public static const ConstID:int = 14;
      
      public static const EXPS:int = 15;
      
      public static const newClass:int = 17;
      
      public static const ERROR:int = 18;
      
      public static const importStm:int = 19;
	  
      public static const threeStm:int = 100;
      
      //public static var names:Array = ["FunDecl","VarDecl","Params","MOP","LOP","COP","Stms","AssignStm","IfElseStm","WhileStm","ForStm","ReturnStm","FunCall","VarID","ConstID","EXPS","","newClass","ERROR","importStm","CLASS","","LOPNot","Nagtive","IDENT","ForInStm","newArray","newObject","Index","SWITCH","CASE","DEFAULT","TRY","CATCH","FINALLY","BREAK","CONTINUE","ELSEIF","PREINCREMENT","INCREMENT"];
	  private static var names:Object;
      public function GNodeType()
      {
         super();
      }
      
      public static function getName(i:int) : String
      {
		  if (names == null){
			  names = {};
			  var dj:DescribeTypeJSON = new DescribeTypeJSON;
			var obj:Object = dj.getClassDescription(GNodeType);
			for each(var a:Object in obj.traits.variables){
				if (a.type == "int"){
					var v:int=GNodeType[a.name]
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

package util 
{
	import parse.Token;
	import parse.TokenType;
	import parser.DY;
	import parser.GNode;
	import parser.GNodeType;
	import parser.GenTree;
	/**
	 * 脚本节点优化
	 * @author lizhi
	 */
	public class Optimize 
	{
		private static var Dy:DY = new DY(new GenTree);
		public function Optimize() 
		{
			
		}
		public static function optimizeTree(a:GenTree){
			for each(var n:GNode in a.fields)
			{
				Optimize.optimize(n);
			}
			for each(var n:GNode in a.motheds)
			{
				Optimize.optimize(n);
			}
			for each(var n:GNode in a.gets)
			{
				Optimize.optimize(n);
			}
			for each(var n:GNode in a.sets)
			{
				Optimize.optimize(n);
			}
		}
		public static function optimize(node:GNode){
			if(node.childs)
			for (var i:int = 0; i < node.childs.length;i++ ){
				var c:GNode = node.childs[i];
				optimize(c);
				if (c.nodeType==GNodeType.ReturnStm){
					node.childs.length = i+1;
					break;
				}
			}
			if (node.nodeType == GNodeType.MOP||node.nodeType==GNodeType.Nagtive){
				var allConst:Boolean = true;
				for each(c in node.childs){
					if (c.nodeType!=GNodeType.ConstID){
						allConst = false;
						break;
					}
				}
				if (allConst){
					var v:Object = Dy.getValue(node);
					node.nodeType = GNodeType.ConstID;
					node.token = new Token;
					node.token.type = TokenType.constant;
					node.token.value = v;
					node.childs = null;// .length = 0;
				}
			}
			
			/*if (node.gtype == GNodeType.newArray){
				if(node.childs.length){
					var exps:GNode = node.childs[0];
					var allConst:Boolean = true;
					for each(c in exps.childs){
						if (c.nodeType!=GNodeType.ConstID){
							allConst = false;
							break;
						}
					}
					if (allConst){
						var arr:Array = [];
						for each(c in exps.childs){
							arr.push(c.value);
						}
						
						node.gtype = GNodeType.ConstID;
						node.token = new Token;
						node.token.type = TokenType.constant;
						node.token.value = arr;
						node.childs.length = 0;
					}
				}
				
			}*/
		}
		
	}

}
package parser{
	import parse.Token;

	public final class GNode{
		/*CONFIG::debug{
		public var lvalue:Object = [];
		}*/
		
		public static var lev: String = "";
		//private static var levs:Array = ["","-","--","---","----","-----","------","--------","--------","---------","----------","-----------","------------","-------------","--------------","---------------","----------------"];

		public var childs: Vector.<parser.GNode> ;

		public var token: Token;

		public var nodeType: int;

		public var defValue:Object;
		//public var vartype: String = "dynamic";

		//public var funtype:int = 0;//0普通 1getter 2setter

		public var word: String;

		//public var istatic: Boolean;
		
		//public var executeST:Function;
		//public var getValue:Function;
		
		public function GNode(n: int = -1, v: Token = null) {
			//this.childs = new Vector.<parser.GNode> ();
			super();
			if (n > -1) {
				this.nodeType = n;
				this.token = v;
				if (n != GNodeType.IDENT) {
					if (this.token) {
						this.word = this.token.word;
					}
				}
			}
		}

		public function get value():  * {
			if (this.token) {
				return this.token.value;
			}
			return null;
		}

		/*public function get line(): int{
			return this.token.line;
		}*/

		/*public function get nodeType(): int{
			return this.gtype;
		}*/

		public function get name(): String{
			if (this.nodeType == GNodeType.AssignStm) {
				return this.childs[0].name;
			}
			if (this.token) {
				return this.token.value;
			}
			return null;
		}

		public function addChild(node: parser.GNode): void{
			if (childs == null) childs = new Vector.<parser.GNode>();
			this.childs.push(node);
		}

		public function toString(): String{
			var o: parser.GNode = null;
			var str: String = nodeTypeName;
			if (this.token) {
				str = str + (" " + this.token.value);
				if (this.nodeType == GNodeType.VarDecl||this.nodeType == GNodeType.FunDecl) {
					//str = this.vartype + " " + str;
				}
			}
			str = lev + str + "\n";
			lev += "    ";
			for each(o in this.childs) {
				if (o is parser.GNode) {
					str = str + (o as parser.GNode).toString();
				} else {
					str = str + ("=======>" + o.toString());
				}
			}
			lev = lev.substr(0, lev.length - 4);
			return str;
		}
		
		public function toAS(): String{
			var o: parser.GNode = null;
			var str: String = nodeTypeName;
			var isDoChild:Boolean = true;
			var i:int = 0;
			if (this.token) {
				str = str + (" " + this.token.value);
				if (this.nodeType == GNodeType.VarDecl) {
					str = "public var " +token.value+":" /*+  this.vartype*/;// + " " + str;
				} else if (this.nodeType == GNodeType.FunDecl) {
					str = "public function " +token.value+"(" + "):" /*+  this.vartype*/;
					i = 1;
				}else if (nodeType==GNodeType.ConstID){
					str = token.value;
				}
			}
			
			if (nodeType==GNodeType.AssignStm){
				isDoChild = false;
				str = childs[0].toAS() + token.value+childs[1].toAS();
			}else if (nodeType==GNodeType.Stms){
				str = "{\n";
			}
			
			if(isDoChild&&childs.length){
				lev += "    ";
				str += "\n";
				for (; i < this.childs.length; i++ ) {
					o = childs[i];
					if (o is parser.GNode) {
						str +=lev + (o as parser.GNode).toAS()+"\n";
					} else {
						str += lev + ("=======>" + o.toAS())+"\n";
					}
				}
				lev = lev.substr(0, lev.length - 4);
			}
			if (nodeType==GNodeType.Stms){
				str += lev+"}\n";
			}
			return str;
		}

		public function get nodeTypeName(): String {
			return GNodeType.getName(this.nodeType);
		}
		
		CONFIG::debug
		public function get code():  String {
			var str:String = "";
			if (token&&token.getLine()){
				return token.getLine().replace(/\t/g,"    ");
			}
			for each(var c:GNode in childs){
				return c.code;
			}
			return null;
		}
		
		CONFIG::debug
		public function get linedepth():  int {
			if (token){
				return token.line
			}
			for each(var c:GNode in childs){
				return c.linedepth
			}
			return -1;
		}
		
		/*public function get nodeType():int 
		{
			return _nodeType;
		}
		
		public function set nodeType(value:int):void 
		{
			_nodeType = value;
			switch(value){
				case GNodeType.INCREMENT:
					executeST = DY.OnINCREMENT;
					break;
				case GNodeType.AssignStm:
					//executeST = DY.OnAssignStm;
					break;
				case GNodeType.COP:
					getValue = DY.OnCOP;
					//executeST=DY.
					break;
				case GNodeType.ConstID:
					getValue = getConstValue;
			}
		}*/
		
	}
}

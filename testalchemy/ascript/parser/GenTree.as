package parser{
	import air.update.descriptors.ConfigurationDescriptor;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import parse.Token;
	import parse.Lex;
	import parse.TokenType;
	import util.Optimize;

	public class GenTree{

		public static var Branch: Object = {};
		public static var staticBranch: Object = {};
		
		private static var staticNodes:Dictionary = new Dictionary;
		//public static var GAPI: Object = {};

		private var tok: Token;

		public var lex: Lex;

		private var index: int = 0;

		public var name: String;

		public var API: Object;

		public var imports: Object;

		public var motheds: Object;

		public var fields: Object;

		public var gets: Object;
		public var sets: Object;
		
		public var innerClasss:Array;

		//public var Package: String = "";
		//构造函数里面存在super么。。。
		public var baseClass: Token;
		public var callSuper: Boolean = false;

		public var instance: DY;
		private static var prioritys: Object = {
			"*": 6,
			"/": 6,
			"%": 6,

			"-": 5,
			"+": 5,

			">>": 4,
			"<<": 4,
			">>>": 4,

			"&": 3,

			"^": 2,

			"|": 1
		}

		static public function createWithGenTree(A: GenTree): GenTree {
			//移除所有静态的字段到B里面
			var B: GenTree = new GenTree();
			B.name = A.name;
			var arr: Array = [];
			for (var n in A.motheds) {
				if (staticNodes[A.motheds[n]]/*.istatic*/) {
					B.motheds[n] = A.motheds[n];
					arr.push(n);
				}
			}
			for each(var n in arr) {
				delete A.motheds[n];
			}
			//
			arr = [];
			for (var n in A.fields) {
				if (staticNodes[A.fields[n]]) {
					B.fields[n] = A.fields[n];
					arr.push(n);
				}
			}
			for each(var n in arr) {
				delete A.fields[n];
			}

			B.instance = new DY(B); //创建一个静态类的实例
			staticBranch[B.name] = B; //静态类
			
			for each(var st:GenTree in A.innerClasss){
				createWithGenTree(st);
				GenTree.Branch[st.name] = st;
			}
			
			return A;
		}

		static public function create(code: String = null,asname:String=null): GenTree{
			var A: GenTree = new GenTree();
			A.asname = asname;
			A.parse(code);

			if (Script.optimize) {
				Optimize.optimizeTree(A);
			}

			return createWithGenTree(A);
		}
		public function GenTree() {
			this.API = {}; //这个对象作为静态方法的代理
			this.imports = {};
			this.motheds = {};
			this.fields = {};
			gets = {};
			sets = {};
			super();
		}
		public function parse(code: String): void{
			if (code) {
				lex = new Lex(code);
				if (lex.isErr){
					trace(asname, "词法分析出错");
					return;
				}
				this.index = 0;
				this.nextToken();
				this.PACKAGE();
				Branch[this.name] = this;
				
				var last:GenTree = this;
				var innterImports:Object = {};
				while (last.tok){
					//trace("lastindex",last.index);
					var now:GenTree = new GenTree;
					now.parseWithLex(lex, last.index - 1);
					if (now.name){
						var ip:Object = now.imports;
						for (var ina:String in ip){
							innterImports[ina] = true;
						}
						now.imports = innterImports;
						
						if (innerClasss==null){
							innerClasss = [];
						}
						innerClasss.push(now);
					}
					//trace("nowindex",now.index);
					last = now;
					//trace("子类",last.name);
				}
				
				for each(now in innerClasss){
					for (var s:String in now.imports){
						var di:int = s.lastIndexOf(".");
						var vname:String = s;
						if (di!=-1){
							vname = s.substr(di + 1);
							//GenTree.GAPI[vname] = s.replace(/\./g, "/");
						}else{
							//GenTree.GAPI[vname] = vname;
						}
						now.API[vname] = Script.getDef(s);
					}
				}
				
			}
		}
		
		public function parseWithLex(lex:Lex,index:int=0):void{
			this.lex = lex;
			this.index = index;
			nextToken();
			PACKAGE();
		}

		public static function hasScript(scname: String): Boolean{
			/*var File: Class = null;
			var FileStream: Class = null;
			var FileMode: Class = null;
			var f: Object = null;
			var fs: Object = null;
			var str: String = null;*/
			//if (Script.app.hasDefinition("flash.filesystem.FileStream")) {
				if (!Branch[scname]) {
					/*File = getDefinitionByName("flash.filesystem.File") as Class;
					FileStream = getDefinitionByName("flash.filesystem.FileStream") as Class;
					FileMode = getDefinitionByName("flash.filesystem.FileMode") as Class;
					f = File.applicationDirectory.resolvePath(Script.scriptdir + scname + ".as");

					if (!f.exists){
					var gcname:String = GAPI[scname];
					if (gcname){
					File = getDefinitionByName("flash.filesystem.File") as Class;
					FileStream = getDefinitionByName("flash.filesystem.FileStream") as Class;
					FileMode = getDefinitionByName("flash.filesystem.FileMode") as Class;
					f = File.applicationDirectory.resolvePath(Script.scriptdir + gcname + ".as");
					}
					}

					if(f.exists){
					fs = new FileStream();
					fs.open(f,FileMode.READ);
					str = fs.readUTFBytes(f.size);
					fs.close();
					//trace("load==" + scname);
					Script.LoadFromString(str);
					}*/
					if (Script.scripts && Script.scripts[scname]) {
						Script.LoadFromString(Script.scripts[scname],scname);
					} else {
						if (Script.ascs) {
							var ascobj: Object = Script.ascs[scname];
						}
						if (ascobj) {
							Script.LoadFromObj(ascobj);
						} else {
							//this.imports
							//trace(scname + "不存在");
						}
					}

				}
			//}
			if (Branch[scname]) {
				return true;
			}
			return false;
		}
		public function declares(_lex: Lex): GNode{
			var tnode: GNode = null;
			this.lex = _lex;
			this.index = 0;
			this.nextToken();
			var cnode: GNode = new GNode(GNodeType.Stms);
			while (this.tok) {
				if (this.tok.type == TokenType.keyvar) {
					tnode = this.varst();
					this.fields[tnode.name] = tnode;
					cnode.addChild(tnode);
				} else if (this.tok.type == TokenType.keyfunction) {
					tnode = this.func();
					this.motheds[tnode.name] = tnode;
				} else {
					tnode = this.st();
					if (tnode.name) {
						this.fields[tnode.name] = tnode;
					}
					cnode.addChild(tnode);
				}
			}
			return cnode;
		}

		/*public function declare(_lex: Lex): GNode{
			var cnode: GNode = null;
			this.lex = _lex;
			this.index = 0;
			this.nextToken();
			if (this.tok.type == TokenType.keyvar) {
				cnode = this.varst();
				this.fields[cnode.name] = cnode;
			} else if (this.tok.type == TokenType.keyfunction) {
				cnode = this.func();
				this.motheds[cnode.name] = cnode;
			} else if (this.tok.type == TokenType.LBRACE) {
				cnode = this.stlist();
			} else {
				cnode = this.st();
			}
			return cnode;
		}*/

		private function doimport(): GNode{
			this.match(TokenType.keyimport);
			var vname_arr: Array = [];
			vname_arr[0] = this.tok.word;
			this.match(TokenType.ident);
			while (this.tok.type == TokenType.DOT) {
				this.match(TokenType.DOT);
				vname_arr.push(this.tok.word);
				nextToken();
				//this.match(TokenType.ident);
			}
			var cnode: GNode = new GNode(GNodeType.importStm);
			cnode.word = vname_arr.join(".");
			this.API[vname_arr[vname_arr.length - 1]] = Script.getDef(cnode.word);
			this.imports[cnode.word] = true;

			//GAPI[vname_arr[vname_arr.length - 1]] = vname_arr.join("/");

			while (this.tok.type == TokenType.Semicolon) {
				this.match(TokenType.Semicolon);
			}
			return cnode;
		}

		private function PACKAGE(): void{
			var vname_arr: Array = null;
			if (this.tok.type == TokenType.keypackage) {
				this.match(TokenType.keypackage);
				if (this.tok.type == TokenType.ident) {
					vname_arr = [];
					vname_arr[0] = this.tok.word;
					this.match(TokenType.ident);
					while (this.tok.type == TokenType.DOT) {
						this.match(TokenType.DOT);
						vname_arr.push(this.tok.word);
						this.match(TokenType.ident);
					}
					//this.Package = vname_arr.join(".");
				}
				this.match(TokenType.LBRACE);
				this.CLASS();
				this.match(TokenType.RBRACE);
			} else {
				this.CLASS();
			}
		}

		private function CLASS(): void{
			while (this.tok.type == TokenType.keyimport) {
				this.doimport();
			}
			if (tok.type==TokenType.LBRACKET){
				while (tok.type!=TokenType.RBRACKET){
					nextToken();
				}
				nextToken();
			}
			switch (this.tok.type) {
			case TokenType.keyclass:
				this.match(TokenType.keyclass);
				this.name = this.tok.word;
				this.match(TokenType.ident);
				if (this.tok.type == TokenType.keyextends) {
					this.match(TokenType.keyextends);
					this.baseClass = this.tok;
					this.match(TokenType.ident);
				}
				
				if (tok.type==TokenType.keyimplements){
					nextToken();
					while (true){
						match(TokenType.ident);
						if (tok.type!=TokenType.COMMA){
							break;
						}
						nextToken();
					}
				}
				
				this.match(TokenType.LBRACE);
				this.DecList();
				this.match(TokenType.RBRACE);
				break;
			default:
				this.error();
			}
		}

		private function DecList(): void{
			var cnode: GNode = null;
			var isBraceing:Boolean = false;
			var vis:Boolean = true;
			while (true){
				if (!(this.tok.type == TokenType.keyimport || this.tok.type == TokenType.keyvar ||
				this.tok.type == TokenType.keyfunction || this.tok.type == TokenType.keystatic || tok.type == TokenType.config || isBraceing))
				{
					break;
				}
				
				if(!isBraceing){
					vis = true;
				}
				if (tok.type == TokenType.config){
					if (!Script.globalAPI[tok.word]){
						vis = false;
					}
					nextToken();
					
					if (tok.type==TokenType.LBRACE){
						isBraceing = true;
						nextToken();
					}
				}
				
				if (isBraceing&&tok.type==TokenType.RBRACE){
					isBraceing = false;
					vis = true;
					nextToken();
				}
				
				if (this.tok.type == TokenType.keystatic) { //静态 =======
					this.nextToken();
					if (this.tok.type == TokenType.keyvar) {
						cnode = this.varst();
						if(vis){
							this.fields[cnode.name] = cnode;
						}
					} else if (this.tok.type == TokenType.keyfunction) {
						cnode = this.func();
						if(vis){
							this.motheds[cnode.name] = cnode;
						}
					}
					staticNodes[cnode] = true;
					//cnode.istatic = true;
				} else {
					if (this.tok.type == TokenType.keyimport) {
						this.doimport();
					} else if (this.tok.type == TokenType.keyvar) {
						cnode = this.varst();
						if(vis){
							this.fields[cnode.name] = cnode;
						}
					} else if (this.tok.type == TokenType.keyfunction) {
						cnode = this.func();
						var funtype: int = node2funtype[cnode];
						if (vis){
							if (funtype == 1) {
								gets[cnode.name] = cnode;
							} else if (funtype == 2) {
								sets[cnode.name] = cnode;
							} else {
								this.motheds[cnode.name] = cnode;
							}
						}
					}else if (tok.type==TokenType.LBRACE){
						var staticNode:GNode = stlist();
					}
				}
			}
		}

		private static var node2funtype: Dictionary = new Dictionary;
		private function func(): GNode{
			var cnode: GNode = null;
			switch (this.tok.type) {
			case TokenType.keyfunction:
				this.match(TokenType.keyfunction);

				var funtype: int = 0;
				if (tok.word == "get") {
					nextToken();
					//match(TokenType.keyget);
					funtype = 1;
				}
				if (tok.word == "set") {
					//match(TokenType.keyset);
					nextToken();
					funtype = 2;
				}

				if (funtype > 0) { //如果判断是getter setter 但是格式不是getter setter，回退成普通函数
					if (tok.type != TokenType.ident) {
						funtype = 0;
						this.tok = this.lex.words[this.index - 2]as Token;
						index--;
					}
				}

				cnode = new GNode(GNodeType.FunDecl, this.tok);
				node2funtype[cnode] = funtype;
				var funcname = this.tok.word;
				//cnode.vartype = "void";
				__callsuper = false;

				this.match(TokenType.ident);

				this.match(TokenType.LParent);
				cnode.addChild(this.ParamList());
				this.match(TokenType.RParent);
				if (this.tok.type == TokenType.Colon) {
					this.match(TokenType.Colon);
					//cnode.vartype = this.tok.word;
					cnode.defValue = DY.GetDefValue(this.tok.word);
					this.match(this.tok.type);
				}
				cnode.addChild(this.stlist());

				if (funcname == this.name && 　__callsuper) { //构造函数内有调用super
					callSuper = true;
				}
				return cnode;
			default:
				this.error();
				return null;
			}
		}

		private function ParamList(): GNode{
			var cnode: GNode = new GNode(GNodeType.Params);
			switch (this.tok.type) {
			case TokenType.ident:
				var pvalue: GNode = new GNode(GNodeType.VarID, this.tok)
					cnode.addChild(pvalue);
				this.match(TokenType.ident);
				if (this.tok.type == TokenType.Colon) //:
				{
					this.match(TokenType.Colon);
					//cnode.vartype = this.tok.word;
					cnode.defValue = DY.GetDefValue(this.tok.word);
					this.match(this.tok.type);
				}

				//默认参数
				if (this.tok.type == TokenType.Assign) {
					match(TokenType.Assign);
					var defvalue: GNode = EXP();
					if (defvalue.nodeType == GNodeType.Nagtive) {
						var ndefvalue: GNode = new GNode;
						ndefvalue.token = new Token;
						ndefvalue.token.value = -defvalue.childs[0].value;
						defvalue = ndefvalue;
					}
					pvalue.addChild(defvalue);

				}
				while (this.tok.type == TokenType.COMMA) //,
				{
					this.match(TokenType.COMMA);
					pvalue = new GNode(GNodeType.VarID, this.tok);
					cnode.addChild(pvalue);
					this.match(TokenType.ident);
					if (this.tok.type == TokenType.Colon) {
						this.match(TokenType.Colon);
						//cnode.vartype = this.tok.word;
						cnode.defValue = DY.GetDefValue(this.tok.word);
						this.match(this.tok.type);
					}

					// todo : 默认参数
					if (this.tok.type == TokenType.Assign) {
						match(TokenType.Assign);
						var defvalue = EXP();
						if (defvalue.nodeType == GNodeType.Nagtive) {
							var ndefvalue: GNode = new GNode;
							ndefvalue.token = new Token;
							ndefvalue.token.value = -defvalue.childs[0].value;
							defvalue = ndefvalue;
						}
						pvalue.addChild(defvalue);
					}
				}
				break;
			case TokenType.RParent:
				break;
			default:
				this.error();
			}
			return cnode;
		}

		private function stlist(): GNode{
			var cnode: GNode = new GNode(GNodeType.Stms);
			switch (this.tok.type) {
			case TokenType.LBRACE:
				this.match(TokenType.LBRACE);
				while (this.tok.type != TokenType.RBRACE) {
					var stnode: GNode = this.st();
					if (tok.type == TokenType.Assign) { //如果是连等，while循环直到不是等号
						var assgns: Array = [stnode];
						while (tok.type == TokenType.Assign) {
							var astnode: GNode = st();
							assgns.unshift(astnode);
						}
						//依次推入
						for each(stnode in assgns) {
							cnode.addChild(stnode);
						}
					} else if (stnode) {
						cnode.addChild(stnode);
					} else {
						break;
					}
				}
				this.match(TokenType.RBRACE);
				break;
			default:
				cnode.addChild(this.st());
				//this.error();
			}
			return cnode;
		}

		private var lastExp: GNode;
		private function st(): GNode{
			var cnode: GNode = null;
			var tnode: GNode = null;
			var ccc: int = 0;
			var tindex: int = 0;
			var tempnode: GNode = null;
			switch (this.tok.type) {
			case TokenType.config:
				var ntk:Token = tok;
				nextToken();
				cnode = st();
				if (Script.globalAPI[ntk.word]){
				}else{
					cnode.childs = null;// .length = 0;
				}
				return cnode;
			case TokenType.LBRACE:
				return stlist();
			case TokenType.keyif:
				cnode = new GNode(GNodeType.IfElseStm);
				//============////============
				tnode = new GNode(GNodeType.ELSEIF);
				this.match(TokenType.keyif);
				this.match(TokenType.LParent);
				tnode.addChild(this.EXP());
				this.match(TokenType.RParent);
				//
				tnode.addChild(this.stlist());
				cnode.addChild(tnode);
				while (this.tok && this.tok.type == TokenType.keyelse) {
					this.match(TokenType.keyelse);
					if (this.tok.type == TokenType.keyif) {
						this.match(TokenType.keyif);
						tnode = new GNode(GNodeType.ELSEIF);
						this.match(TokenType.LParent);
						tnode.addChild(this.EXP());
						this.match(TokenType.RParent);
						tnode.addChild(this.stlist());
						cnode.addChild(tnode);
					} else {
						cnode.addChild(this.stlist());
					}
				}
				return cnode;
			case TokenType.keyfor:
				this.match(TokenType.keyfor);
				if (this.tok.type == TokenType.keyeach) {
					this.match(TokenType.keyeach);
					this.match(TokenType.LParent);
					cnode = new GNode(GNodeType.ForEACHStm);
					if (this.tok.type == TokenType.keyvar) {
						this.match(TokenType.keyvar);
					}
					if (this.tok.type == TokenType.ident) {
						cnode.addChild(new GNode(GNodeType.VarDecl, this.tok));
						this.match(TokenType.ident);
						if (this.tok.type == TokenType.Colon) {
							this.match(TokenType.Colon);
							//cnode.childs[0].vartype = this.tok.word;
							cnode.childs[0].defValue = DY.GetDefValue(this.tok.word);
							this.match(this.tok.type);
						}
						this.match(TokenType.COP, "in");
						cnode.addChild(this.EXP());
						this.match(TokenType.RParent);
						cnode.addChild(this.stlist());
					} else {
						throw Error("for each 匹配失败");
					}
				} else {
					this.match(TokenType.LParent);
					var i: int = index + 1;
					var isForin: Boolean = false;
					while (true) {
						var nt: Token = this.lex.words[i++];
						if (nt == null) {
							break;
						}
						if (nt.type == TokenType.RParent) {
							break;
						}
						if (nt.word == "in") {
							isForin = true;
							break;
						}
					}
					if (isForin /*this.lex.words[this.index + 1].type == TokenType.Colon || this.lex.words[this.index + 2].type == TokenType.Colon*/) {
						cnode = new GNode(GNodeType.ForInStm);
						if (this.tok.type == TokenType.keyvar) {
							this.match(TokenType.keyvar);
						}
						if (this.tok.type == TokenType.ident) {
							cnode.addChild(new GNode(GNodeType.VarDecl, this.tok));
							this.match(TokenType.ident);
							//this.match(TokenType.COP, "in");
							while (true) {
								nextToken();
								if (tok == null || tok.word == "in") {
									nextToken();
									break;
								}
							}
							cnode.addChild(this.EXP());
							this.match(TokenType.RParent);
							cnode.addChild(this.stlist());
						} else {
							throw Error("for in 匹配失败");
						}
					} else {
						cnode = new GNode(GNodeType.ForStm);
						cnode.addChild(this.st());
						cnode.addChild(this.EXP());
						this.match(TokenType.Semicolon);
						var stms:Vector.<GNode> = new Vector.<GNode>;
						if (tok.type != TokenType.RParent){
							while (true){
								stms.push(st());
								if (tok.type==TokenType.COMMA){
									nextToken();
								}else{
									break;
								}
								//cnode.addChild(this.st());
							}
						}
						
						if (stms.length==1){
							cnode.addChild(stms[0]);
						}else{
							var stmn:GNode = new GNode(GNodeType.Stms);
							stmn.childs = stms;
							cnode.addChild(stmn);
						}
						
						/*if (tok.type!=TokenType.RParent){
							while (tok.type!=TokenType.RParent){
								cnode.addChild(this.st());
							}
						}*/
						
						this.match(TokenType.RParent);
						cnode.addChild(this.stlist());
					}
				}
				return cnode;
			case TokenType.keywhile:
				cnode = new GNode(GNodeType.WhileStm);
				this.match(TokenType.keywhile);
				this.match(TokenType.LParent);
				cnode.addChild(this.EXP());
				this.match(TokenType.RParent);
				cnode.addChild(this.stlist());
				return cnode;
			case TokenType.keytry:
				cnode = new GNode(GNodeType.TRY);
				this.match(TokenType.keytry);
				cnode.addChild(this.stlist());
				if (this.tok.type == TokenType.keycatch) {
					tnode = new GNode(GNodeType.CATCH);
					this.match(TokenType.keycatch);
					this.match(TokenType.LParent);
					if (this.tok.type == TokenType.ident) {
						tempnode = new GNode(GNodeType.VarID, this.tok);
						tnode.addChild(tempnode);
						this.match(TokenType.ident);
						if (this.tok.type == TokenType.Colon) {
							this.match(TokenType.Colon);
							//tempnode.vartype = this.tok.word;
							tempnode.defValue = DY.GetDefValue(this.tok.word);
							this.match(this.tok.type);
						}
					} else {
						this.error();
					}
					this.match(TokenType.RParent);
					tnode.addChild(this.stlist());
					cnode.addChild(tnode);
					if (this.tok.type == TokenType.keyfinally) {
						this.match(TokenType.keyfinally);
						cnode.addChild(this.stlist());
					}
				} else {
					this.error();
				}
				return cnode;
			case TokenType.keyswitch:
				cnode = new GNode(GNodeType.SWITCH);
				this.match(TokenType.keyswitch);
				this.match(TokenType.LParent);
				cnode.addChild(this.EXP());
				this.match(TokenType.RParent);
				this.match(TokenType.LBRACE);
				ccc = 0;
				while (this.tok.type == TokenType.keycase) {
					tnode = new GNode(GNodeType.CASE);
					this.match(TokenType.keycase);
					tnode.addChild(this.EXP());
					this.match(TokenType.Colon);
					ccc = 0;
					while (this.tok.type != TokenType.keycase && this.tok.type != TokenType.keydefault && this.tok.type != TokenType.RBRACE) {
						ccc++;
						if (tnode == null) {
							trace("分析case出现严重错误");
						}
						tnode.addChild(this.st());
						if (ccc > 200) {
							trace("分析case结构陷入死循环，请查看case部分代码");
							break;
						}
					}
					cnode.addChild(tnode);
				}
				if (this.tok.type == TokenType.keydefault) {
					tnode = new GNode(GNodeType.DEFAULT);
					this.match(TokenType.keydefault);
					this.match(TokenType.Colon);
					while (this.tok.type != TokenType.RBRACE) {
						tnode.addChild(this.st());
					}
					cnode.addChild(tnode);
				}
				this.match(TokenType.RBRACE);
				return cnode;
			case TokenType.keyvar:
				return this.varst();
			case TokenType.ident:
				tindex = this.index;
				tnode = this.IDENT();
				if (this.tok.type == TokenType.Assign) {
					cnode = new GNode(GNodeType.AssignStm, this.tok);
					cnode.addChild(tnode);
					this.match(TokenType.Assign);
					lastExp = EXP();
					cnode.addChild(lastExp);
					while (this.tok.type == TokenType.Semicolon) {
						this.match(TokenType.Semicolon);
					}
				} else {
					this.index = tindex - 1;
					this.nextToken();
					cnode = this.EXP();
					while (Boolean(this.tok) && this.tok.type == TokenType.Semicolon) {
						this.match(TokenType.Semicolon);
					}
				}
				return cnode;
			case TokenType.Assign:
				tnode = lastExp;
				cnode = new GNode(GNodeType.AssignStm, this.tok);
				cnode.addChild(tnode);
				match(TokenType.Assign);
				lastExp = EXP();
				cnode.addChild(lastExp);
				while (this.tok.type == TokenType.Semicolon) {
					this.match(TokenType.Semicolon);
				}
				return cnode;
				/*case TokenType.DOT:
				this.match(TokenType.DOT);
				tnode = new GNode(GNodeType.VarID, this.tok);
				lastExp.addChild(tnode);
				this.match(TokenType.ident);
				return cnode;*/
			case TokenType.LParent:
			case TokenType.constant:
			case TokenType.keynew:
			case TokenType.LOPNot:
			case TokenType.INCREMENT:
				cnode = this.EXP();
				lastExp = cnode;
				while (this.tok.type == TokenType.Semicolon) {
					this.match(TokenType.Semicolon);
				}
				return cnode;
			case TokenType.MOP:
				if (this.tok.word == "-") {
					cnode = this.EXP();
					while (this.tok.type == TokenType.Semicolon) {
						this.match(TokenType.Semicolon);
					}
					return cnode;
				}
				if (this.tok.word == "/"){
					//正则表达式
					cnode = EXP();
					lastExp = cnode;
					while (this.tok.type == TokenType.Semicolon) {
						this.match(TokenType.Semicolon);
					}
					return cnode;
				}
				break;
			case TokenType.keyreturn:
				cnode = new GNode(GNodeType.ReturnStm, this.tok);
				this.match(TokenType.keyreturn);
				if (this.tok.type != TokenType.Semicolon) {
					try {
						cnode.addChild(this.EXP());
					} catch (err: Error) {}
				}
				while (tok.type == TokenType.Semicolon) {
					this.match(TokenType.Semicolon);
				}
				return cnode;
			case TokenType.keyimport:
				return this.doimport();
			case TokenType.keycontinue:
				cnode = new GNode(GNodeType.CONTINUE);
				cnode.word = this.tok.word;
				this.match(TokenType.keycontinue);
				while (this.tok.type == TokenType.Semicolon) {
					this.match(TokenType.Semicolon);
				}
				return cnode;
			case TokenType.keybreak:
				cnode = new GNode(GNodeType.BREAK);
				cnode.word = this.tok.word;
				this.match(TokenType.keybreak);
				while (this.tok.type == TokenType.Semicolon) {
					this.match(TokenType.Semicolon);
				}
				return cnode;
			default:
				this.error();
			}
			return null;
		}

		private function varst(): GNode{
			var tnode: GNode = null;
			var cnode: GNode = null;
			switch (this.tok.type) {
			case TokenType.keyvar:
				this.match(TokenType.keyvar);
				tnode = new GNode(GNodeType.VarDecl, this.tok);
				this.match(TokenType.ident);
				if (this.tok.type == TokenType.Colon) {
					this.match(TokenType.Colon);
					//tnode.vartype = this.tok.word;
					tnode.defValue = DY.GetDefValue(this.tok.word);
					this.match(this.tok.type);
					if (tok.type == TokenType.DOT){
						nextToken();
						
						if (tok.word == "<") { // todo : vector
							nextToken();

							if (tok.type == TokenType.ident) {
								var typeword:String = tok.word;
								/*var truetype: String = null;
								if (typeword == "uint") {
									truetype = typeword;
								} else if (typeword == "int") {
									truetype = typeword;
								} else if (typeword == "Number") {
									truetype = typeword;
								} else {
									truetype = "Object";
								}*/
								/*cnode.childs[0].word = "__AS3__.vec.Vector.<" + truetype + ">";
								cnode.childs[0].token.word = cnode.childs[0].word;
								cnode.childs[0].token.value = cnode.childs[0].word;
								cnode.childs[0].name;*/
								//trace(1);
								tnode.defValue = null;
								//tnode.vartype="__AS3__.vec.Vector.<" + typeword + ">"
							}
							this.match(TokenType.ident);
							if (tok.word == ">") {
								nextToken();
							}
						}
					}
				}
				if (this.tok.type == TokenType.Assign) {
					cnode = new GNode(GNodeType.AssignStm, this.tok);
					this.match(TokenType.Assign);
					cnode.addChild(tnode);
					cnode.addChild(this.EXP());
					while (this.tok.type == TokenType.Semicolon) {
						this.match(TokenType.Semicolon);
					}
					return cnode;
				}
				while (Boolean(this.tok) && this.tok.type == TokenType.Semicolon) {
					this.match(TokenType.Semicolon);
				}
				return tnode;
			default:
				this.error();
				return null;
			}
		}

		private function _EXP(): GNode{
			var tnode: GNode = null;
			var cnode: GNode = null;
			var cn: GNode = null;
			var tk: Token = null;
			switch (this.tok.type) {
			case TokenType.ident:
			case TokenType.constant:
			case TokenType.LParent:
			case TokenType.keynew:
			case TokenType.LOPNot:
			case TokenType.INCREMENT:
			case TokenType.config:
				tnode = this.Term();
				if (Boolean(this.tok) && this.tok.type == TokenType.LOP) {
					cnode = new GNode(GNodeType.LOP, this.tok);
					this.match(TokenType.LOP);
					cnode.addChild(tnode);
					cnode.addChild(this.EXP());
					return cnode;
				}
				return tnode;
			case TokenType.MOP:
				if (this.tok.word == "-") {
					tnode = this.Term();
					if (this.tok.type == TokenType.LOP) {
						cnode = new GNode(GNodeType.LOP, this.tok);
						this.match(TokenType.LOP);
						cnode.addChild(tnode);
						cnode.addChild(this.EXP());
						return cnode;
					}
					return tnode;
				}else if (tok.word=="/"){//代码从keynew复制过来的
					tnode = this.Term();
					if (Boolean(this.tok) && this.tok.type == TokenType.LOP) {
						cnode = new GNode(GNodeType.LOP, this.tok);
						this.match(TokenType.LOP);
						cnode.addChild(tnode);
						cnode.addChild(this.EXP());
						return cnode;
					}
					return tnode;
				}
				break;
			case TokenType.LBRACKET:
				this.match(TokenType.LBRACKET);
				tnode = new GNode(GNodeType.newArray);
				if (this.tok.type != TokenType.RBRACKET) {
					tnode.addChild(this.EXPList());
				}
				this.match(TokenType.RBRACKET);
				return tnode;
			case TokenType.LBRACE:
				this.match(TokenType.LBRACE);
				tnode = new GNode(GNodeType.newObject);
				if (this.tok.type == TokenType.RBRACE) {
					this.match(TokenType.RBRACE);
					return tnode;
				}
				do {
					if (this.tok.type == TokenType.COMMA) {
						this.match(TokenType.COMMA);
					}
					cn = new GNode(GNodeType.VarID, this.tok);
					cn.word = this.tok.word;
					tnode.addChild(cn);
					this.match(TokenType.ident);
					this.match(TokenType.Colon);
					if (this.tok.type == TokenType.COMMA || this.tok.type == TokenType.RBRACE) {
						tk = new Token();
						tk.value = "";
						tnode.addChild(new GNode(GNodeType.ConstID, tk));
					} else {
						tnode.addChild(this.EXP());
					}
				} while (this.tok.type == TokenType.COMMA);

				this.match(TokenType.RBRACE);
				return tnode;
			default:
				this.error();
			}
			return null;
		}

		private function EXP(): GNode {
			var exp0: GNode = this._EXP();
			if (tok.type == TokenType.Question) {
				nextToken();
				var exp1: GNode = _EXP();
				match(TokenType.Colon);
				var exp2: GNode = _EXP();
				var tnode: GNode = new GNode(GNodeType.threeStm);
				tnode.addChild(exp0);
				tnode.addChild(exp1);
				tnode.addChild(exp2);
			} else {
				tnode = exp0;
			}

			if (tok.type == TokenType.DOT) {
				this.match(TokenType.DOT);
				if (tnode.nodeType != TokenType.ident) {
					var identNode: GNode = new GNode;
					identNode.nodeType = GNodeType.IDENT;
					identNode.addChild(tnode);
					tnode = identNode;
				}
				var exp1: GNode = EXP();
				for each(var c: GNode in exp1.childs) {
					tnode.addChild(c);
				}
			}

			return tnode;
		}

		private function EXPList(): GNode{
			var cnode: GNode = new GNode(GNodeType.EXPS);
			switch (this.tok.type) {
			case TokenType.ident:
			case TokenType.constant:
			case TokenType.LParent:
			case TokenType.keynew:
			case TokenType.LOPNot:
			case TokenType.INCREMENT:
			case TokenType.LBRACKET:
			case TokenType.LBRACE:

				cnode.addChild(EXP());
				while (this.tok.type == TokenType.COMMA) {
					this.match(TokenType.COMMA);
					cnode.addChild(EXP());
				}
				return cnode;
			case TokenType.MOP:
				if (this.tok.word == "-"||tok.word=="/") {
					cnode.addChild(this.EXP());
					while (this.tok.type == TokenType.COMMA) {
						this.match(TokenType.COMMA);
						cnode.addChild(this.EXP());
					}
					return cnode;
				}
				break;
			default:
				this.error();
			}
			return null;
		}

		private function Term(): GNode{
			var tnode: GNode = null;
			var cnode: GNode = null;
			switch (this.tok.type) {
			case TokenType.ident:
			case TokenType.constant:
			case TokenType.LParent:
			case TokenType.keynew:
			case TokenType.LOPNot:
			case TokenType.INCREMENT:
			case TokenType.config:
				tnode = this.facter();
				if (Boolean(this.tok) && this.tok.type == TokenType.COP) {
					cnode = new GNode(GNodeType.COP, this.tok);
					this.match(TokenType.COP);
					cnode.addChild(tnode);
					cnode.addChild(this.Term());
					return cnode;
				}
				return tnode;
			case TokenType.MOP:
				if (this.tok.word == "-") {
					tnode = this.facter();
					if (Boolean(this.tok) && this.tok.type == TokenType.COP) {
						cnode = new GNode(GNodeType.COP, this.tok);
						this.match(TokenType.COP);
						cnode.addChild(tnode);
						cnode.addChild(this.Term());
						return cnode;
					}
					return tnode;
				}else if (tok.word=="/"){//代码从keynew 复制过来的
					tnode = this.facter();
					if (Boolean(this.tok) && this.tok.type == TokenType.COP) {
						cnode = new GNode(GNodeType.COP, this.tok);
						this.match(TokenType.COP);
						cnode.addChild(tnode);
						cnode.addChild(this.Term());
						return cnode;
					}
					return tnode;
				}
				
				break;
			default:
				this.error();
			}
			return null;
		}

		private function priority(s: GNode): int{
			/*if(s.nodeType == GNodeType.MOP){
			if (s.word=="^"){
			return 1;
			}else if(s.word == "+" || s.word == "-"){
			return 2;
			}
			return 3;
			}
			return 4;*/
			return prioritys[s.word] || 1000;
		}

		private function MopFactor(): GNode{
			var tnode: GNode = null;
			var cnode: GNode = null;
			var i: int = 0;
			var ccc: String = null;
			var pri: int = 0;
			var len: int = 0;
			var right: GNode = null;
			var left: GNode = null;
			var nodearr: Array = [];
			var stack: Array = [];
			nodearr.push(this.gene());
			if (Boolean(this.tok) && this.tok.type == TokenType.MOP) {
				while (this.tok.type == TokenType.MOP) {
					cnode = new GNode(GNodeType.MOP, this.tok);
					pri = this.priority(cnode);
					if (stack.length != 0) {
						len = stack.length - 1;
						for (i = len; i >= 0; ) {
							if (this.priority(stack[i]as GNode) >= pri) {
								nodearr.push(stack.pop());
								i--;
								continue;
							}
							break;
						}
					}
					stack.push(cnode);
					this.match(TokenType.MOP);
					nodearr.push(this.gene());
				}
				while (stack.length > 0) {
					nodearr.push(stack.pop());
				}
				ccc = "";
				for (i = 0; i < nodearr.length; i++) {
					ccc = ccc + ((nodearr[i]as GNode).word + ".");
				}
				for (i = 0; i < nodearr.length; i++) {
					if (((nodearr[i]as GNode).childs==null||(nodearr[i]as GNode).childs.length == 0) && (nodearr[i]as GNode).nodeType == GNodeType.MOP) {
						tnode = nodearr[i]as GNode;
						right = stack.pop();
						left = stack.pop();
						tnode.addChild(left);
						tnode.addChild(right);
						stack.push(tnode);
					} else {
						stack.push(nodearr[i]);
					}
				}
				if (stack.length == 1) {
					return stack[0];
				}
				this.error();
			}
			return nodearr[0];
		}

		private function facter(): GNode{
			switch (this.tok.type) {
			case TokenType.ident:
			case TokenType.constant:
			case TokenType.LParent:
			case TokenType.keynew:
			case TokenType.LOPNot:
			case TokenType.INCREMENT:
			case TokenType.config:
				return this.MopFactor();
			case TokenType.MOP:
				if (this.tok.word == "-") {
					return this.MopFactor();
				}else if (tok.word=="/"){
					return this.MopFactor();
				}
				break;
			default:
				this.error();
			}
			return null;
		}
		public var asname:String;
		private var __callsuper: Boolean = false;
		private function IDENT(): GNode{
			var tnode: GNode = null;
			var cnode: GNode = null;
			switch (this.tok.type) {
			case TokenType.ident:
				cnode = new GNode(GNodeType.IDENT);
				tnode = new GNode(GNodeType.VarID, this.tok);
				cnode.addChild(tnode);

				//
				this.match(TokenType.ident);
				if (tnode.word == "super" && this.tok.type == TokenType.LParent) {
					__callsuper = true;
				}
				while (true) //this.tok.type == TokenType.LBRACKET || this.tok.type == TokenType.DOT || this.tok.type ==TokenType.LParent
				{
					if (this.tok.type == TokenType.LParent) {
						tnode = new GNode(GNodeType.FunCall);
						cnode.addChild(tnode);
						this.match(TokenType.LParent);
						if (this.tok.type != TokenType.RParent) {
							tnode.addChild(this.EXPList());
						}
						this.match(TokenType.RParent);
					} else if (this.tok.type == TokenType.LBRACKET) {
						this.match(TokenType.LBRACKET);
						tnode = new GNode(GNodeType.Index);
						tnode.addChild(this.EXP());
						//
						cnode.addChild(tnode);
						this.match(TokenType.RBRACKET);
					} else if (this.tok.type == TokenType.DOT) {
						this.match(TokenType.DOT);

						if (tok.word == "<") { // todo : vector
							nextToken();

							if (tok.type == TokenType.ident) {
								var typeword: String = tok.word;
								var truetype: String = null;
								if (typeword == "uint") {
									truetype = typeword;
								} else if (typeword == "int") {
									truetype = typeword;
								} else if (typeword == "Number") {
									truetype = typeword;
								} else {
									truetype = "Object";
								}
								cnode.childs[0].word = "__AS3__.vec.Vector.<" + truetype + ">";
								cnode.childs[0].token.word = cnode.childs[0].word;
								cnode.childs[0].token.value = cnode.childs[0].word;
							}

							//cnode.childs[0].word += "." + tok.word;
							this.match(TokenType.ident);
							if (tok.word == ">") {
								nextToken();
							}
						} else {
							tnode = new GNode(GNodeType.VarID, this.tok);
							cnode.addChild(tnode);
							this.match(TokenType.ident);
						}
					} else {
						break;
					}
				}
				return cnode;
			default:
				this.error();
				return null;
			}
		}

		private function gene(): GNode{
			var cnode: GNode = null;
			var tnode: GNode = null;
			var id: GNode = null;
			switch (this.tok.type) {
			case TokenType.config:
				var newtk:Token = new Token;
				newtk.value = Script.globalAPI[tok.word];
				newtk.word = newtk.value+"";
				
				cnode = new GNode(GNodeType.ConstID, newtk);
				cnode.word = this.tok.word;
				nextToken();
				return cnode;
			case TokenType.constant:
				//////////////debug
				/*tnode = this.IDENT();

				if(this.tok.type == TokenType.INCREMENT)
			{
				cnode = new GNode(GNodeType.INCREMENT);
				cnode.word = this.tok.word;
				cnode.addChild(tnode);
				this.match(TokenType.INCREMENT);
				return cnode;
				}
				return tnode;*/
				///////////////


				cnode = new GNode(GNodeType.ConstID, this.tok);
				cnode.word = this.tok.word;
				this.match(TokenType.constant);

				/*var node1:GNode = new GNode(GNodeType.AssignStm, this.tok);
				var node2:GNode = new GNode(GNodeType.VarID);
				node1.addChild(

				if (tok.type == TokenType.DOT){
				while(true)//this.tok.type == TokenType.LBRACKET || this.tok.type == TokenType.DOT || this.tok.type ==TokenType.LParent{
				if(this.tok.type == TokenType.LParent){
				tnode = new GNode(GNodeType.FunCall);
				cnode.addChild(tnode);
				this.match(TokenType.LParent);
				if(this.tok.type != TokenType.RParent){
				tnode.addChild(this.EXPList());
				}
				this.match(TokenType.RParent);
				}
				else if(this.tok.type == TokenType.LBRACKET){
				this.match(TokenType.LBRACKET);
				tnode = new GNode(GNodeType.Index);
				tnode.addChild(this.EXP());
				//
				cnode.addChild(tnode);
				this.match(TokenType.RBRACKET);
				}
				else if(this.tok.type == TokenType.DOT){
				this.match(TokenType.DOT);
				tnode = new GNode(GNodeType.VarID, this.tok);
				cnode.addChild(tnode);
				this.match(TokenType.ident);
				}else {
				break;
				}
				}
				return cnode;
				}*/

				return cnode;
			case TokenType.LParent:
				this.match(TokenType.LParent);
				cnode = this.EXP();
				this.match(TokenType.RParent);
				return cnode;
			case TokenType.keynew:
				cnode = new GNode(GNodeType.newClass, this.tok);
				this.match(TokenType.keynew);
				id = new GNode(GNodeType.VarID, this.tok);
				cnode.addChild(id);
				this.match(TokenType.ident);
				while (this.tok.type == TokenType.DOT) {
					this.match(TokenType.DOT);
					// todo : new vector
					if (tok.word == "<") {
						nextToken();
						if (tok.type == TokenType.ident) {
							var typeword: String = tok.word;
							var truetype: String = null;
							if (typeword == "uint") {
								truetype = typeword;
							} else if (typeword == "int") {
								truetype = typeword;
							} else if (typeword == "Number") {
								truetype = typeword;
							} else {
								truetype = "Object";
							}
							cnode.childs[0].word = "__AS3__.vec.Vector.<" + truetype + ">";
						}
						match(TokenType.ident);
						if (tok.word == ">") {
							match(TokenType.COP, ">");
						}
					} else {
						id.word = id.word + ("." + this.tok.word);
						this.match(TokenType.ident);
					}
				}
				if (this.tok.type == TokenType.LParent) {
					this.match(TokenType.LParent);
					if (this.tok.type != TokenType.RParent) {
						cnode.addChild(this.EXPList());
					}
					this.match(TokenType.RParent);
				}

				//后面可能还有代码。。包括后续的属性访问等。。。
				//以后有时间再加。。。。。。。。。。。。
				return cnode;
			case TokenType.ident:
				tnode = this.IDENT();

				if (this.tok.type == TokenType.INCREMENT) {
					cnode = new GNode(GNodeType.INCREMENT);
					cnode.word = this.tok.word;
					cnode.addChild(tnode);
					this.match(TokenType.INCREMENT);
					return cnode;
				}
				return tnode;
			case TokenType.LOPNot:
				this.match(TokenType.LOPNot);
				tnode = this.gene();
				cnode = new GNode(GNodeType.LOPNot);
				cnode.word = "!";
				cnode.addChild(tnode);
				return cnode;
			case TokenType.MOP:
				if (this.tok.word == "-") {
					this.match(TokenType.MOP);
					tnode = this.gene();
					cnode = new GNode(GNodeType.Nagtive);
					cnode.word = "-";
					cnode.addChild(tnode);
					return cnode;
				}
				if(tok.word=="/"){
					nextToken();
					if (tok.type==TokenType.ident){
						//trace("reg", tok.word);
						var reg1:String = tok.word;
						nextToken();
					}else{
						error();
					}
					match(TokenType.MOP, "/");
					if (tok.type==TokenType.ident){
						var reg2:String = tok.word;
						//trace("reg", tok.word);
						nextToken();
					}
					while (this.tok.type == TokenType.Semicolon) {
						this.match(TokenType.Semicolon);
					}
					cnode = new GNode;
					cnode.nodeType = GNodeType.newClass;
					lastExp = cnode;
					var varid:GNode = new GNode;
					varid.nodeType = GNodeType.VarID;
					varid.word = "RegExp";
					varid.token = new Token;
					varid.token.word = varid.token.value = varid.word;
					cnode.addChild(varid);
					var exps:GNode = new GNode;
					exps.nodeType = GNodeType.EXPS;
					cnode.addChild(exps);
					var c1:GNode = new GNode;
					c1.nodeType = GNodeType.ConstID;
					c1.word = reg1.replace(/\\/g,"\\\\");
					c1.token = new Token;
					c1.token.word = c1.token.value = reg1;
					exps.addChild(c1);
					if (reg2){
						c1 = new GNode;
						c1.nodeType = GNodeType.ConstID;
						c1.word = reg2;
						c1.token = new Token;
						c1.token.word = c1.token.value = reg2;
						exps.addChild(c1);
					}
					return cnode;
				}
				break;
			case TokenType.INCREMENT:
				cnode = new GNode(GNodeType.PREINCREMENT);
				cnode.word = this.tok.word;
				this.match(TokenType.INCREMENT);
				cnode.addChild(this.gene());
				return cnode;
			default:
				this.error();
			}
			return null;
		}

		private function nextToken(): void{
			this.tok = this.lex.words[this.index++]as Token;
		}

		private function match(type: int, word:  *  = null): void{
			if (type == this.tok.type && (word == null || this.tok.word == word)) {
				this.nextToken();
			} else {
				this.error();
			}
		}

		private function error(): void{
			CONFIG::debug{
			var msg: String = this.name + "语法错误>行号:" + this.tok.line + "," + this.tok.getLine() + "，单词：" + this.tok.word;
			
			}
			CONFIG::release{
				
				var msg: String = this.name + "语法错误>行号:"  + "," + "，单词：" + this.tok.word;
			
			}
			
			//trace(msg);
			throw new Error(msg);
		}
		public function toString(): String{
			var o:  *  = null;
			var c: String = null;
			var str: String = "";
			str = str + ("package" /*+ this.Package*/ + "{\r");
			for (o in this.imports) {
				str = str + ("import " + o + ";\r");
			}
			str = str + ("class " + this.name + "{\r");
			for (o in this.fields) {
				c = (this.fields[o]as GNode).toString();
				str = str + (c + "\r");
			}
			for (o in this.motheds) {
				c = (this.motheds[o]as GNode).toString();
				str = str + (c + "\r");
			}
			str = str + "}\r";
			str = str + "}";

			return str; //.replace(/protected/g,"");
		}

		public function toAS(): String{
			var o:  *  = null;
			var c: String = null;
			var str: String = "";
			str = str + ("package" /*+ this.Package*/ + "{\r");
			for (o in this.imports) {
				str = str + ("import " + o + ";\r");
			}
			str = str + ("class " + this.name + "{\r");
			for (o in this.fields) {
				c = (this.fields[o]as GNode).toAS();
				str = str + (c + "\r");
			}
			for (o in this.motheds) {
				c = (this.motheds[o]as GNode).toAS();
				str = str + (c + "\r");
			}
			str = str + "}\r";
			str = str + "}";

			return str; //.replace(/protected/g,"");
		}
	}
}

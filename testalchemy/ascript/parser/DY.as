package parser
{
	import flash.filesystem.File;
	import flash.utils.getQualifiedClassName;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import parse.ProxyFunc;
	import parse.Token;
	import parse.TokenType;
	
	public dynamic class DY extends Proxy
	{
		public static var stacks:Array = [];
		protected var __rootnode:parser.GenTree;
		protected var __static_rootnode:parser.GenTree;
		
		public var _classname:String;
		
		protected var __vars:Object;
		
		private var local_vars:Array;
		private var customBase:Object;
		
		protected var __API:Object;
		
		protected var __object:Object;
		protected var __super:Object;
		
		protected var isret:Boolean = false;
		
		protected var jumpstates:Array;
		
		protected var lvalue:parser.LValue;
		
		public function get base():*
		{
			return __super;
		}
		
		public function DY(rootTree:GenTree, explist:Array = null,customBase:Object=null)
		{
			/*CONFIG::debug{
				trace("dy-----------------")
				trace(rootTree.toAS());
				trace("-----------------")
			}*/
			
			this.customBase = customBase;
			var o:* = null;
			this.jumpstates = [0];
			this.lvalue = new parser.LValue();
			super();
			this._classname = rootTree.name;
			this.__rootnode = rootTree;
			__static_rootnode = parser.GenTree.staticBranch[_classname];
			
			this.local_vars = [];
			this.__API = __rootnode.API;
			this.__API._root = Script._root;
			
			this.__object = {};
			this.init(explist || []);
		}
		
		public function toString():String
		{
			return this._classname;
		}
		
		override flash_proxy function callProperty(methodName:*, ... args):*
		{
			//trace("callproperty",methodName,args);
			
			if (methodName is QName)
			{
				methodName = (methodName as QName).localName;
			}
			
			if (this.__rootnode.motheds[methodName])
			{
				return this.call(methodName, args);
			}
			if (this.__object[methodName] is Function)
			{
				return this.callLocalFunc(this.__object, methodName, args);
			}
			//hasOwnProperty
			if (this.__super && this.__super[methodName] is Function)
			{
				return this.callLocalFunc(this.__super, methodName, args);
			}
			DY.executeError(this._classname + ">SUPER " + this.__object + ">不存在此方法=" + methodName);
			return null;
		}
		
		override flash_proxy function getProperty(vname:*):*
		{
			//trace("getProperty",vname);
			var na = vname.localName;
			if (this._rootnode.motheds[na] != undefined)
			{
				return ProxyFunc.getAFunc(this, na);//返回函数
			}
			
			if (__rootnode.fields[na])
			{
				return this.__object[na];
			}
			
			if (__rootnode.gets[na])
			{
				return ProxyFunc.getAFunc(this, na)();
			}
			
			if (this.__super)
			{
				if (this.__super is DY)
				{
					return __super[na];
					
				}
				else if (__super.hasOwnProperty(na))
				{
					return __super[na];
				}
			}
			return undefined;
		}
		
		//
		override flash_proxy function hasProperty(vname:*):Boolean
		{
			if (__rootnode.fields[vname] || __rootnode.motheds[vname] || __rootnode.sets[vname] || __rootnode.gets[vname] || __super && __super.hasOwnProperty(vname))
			{
				//trace("hasproperty",vname,true);
				return true;
			}
			// trace("hasproperty", vname, false, typeof(__rootnode));
			return false;
		}
		
		override flash_proxy function setProperty(vname:*, value:*):void
		{
			//trace("setproperty",vname,value);
			var na = vname.localName;
			if (__rootnode.fields[na])
			{
				this.__object[na] = value;
				return;
			}
			else if (__rootnode.sets[na])
			{
				ProxyFunc.getAFunc(this, na)(value);
				return;
			}
			this.__super[na] = value;
		}
		
		public function get _rootnode():parser.GenTree
		{
			return this.__rootnode;
		}
		
		private function init(explist:Array):void
		{
			var o:GNode = null;
			
			if (__rootnode.baseClass)
			{//存在父类
				if (!__rootnode.callSuper)
				{
					var identnode:Token = __rootnode.baseClass;// GenTree.Branch[__rootnode.baseClass.word].motheds[__rootnode.baseClass];
					//
					var arrr = identnode.value.split(".");
					var c = null;
					if (this.__API[arrr[arrr.length - 1]])
					{
						c = this.__API[arrr[arrr.length - 1]];
					}
					else if (Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.value))
					{
						c = Script.getDef(identnode.value) as Class;
					}
					if (c)
					{
						if (c is Class&&customBase&&(customBase is c)){
							__super = customBase;
						}else{
							__super = newLocalClass(c, []);
						}
						try{
							__super["__child"] = this;
						}catch (err:Error){
							
						}
					}
					else if (parser.GenTree.hasScript(identnode.value))
					{
						__super = new DY(GenTree.Branch[identnode.value], []);
						//trace("成功创建脚本类=" + identnode.word + "的实例");
					}
					else
					{
						//E:\proj\cq_client\client\v1.0_script\src\testscript\TestStage3D.as:33: Error: Access of possibly undefined property fdsaf.
						
						CONFIG::debug{
						trace(Script.scriptdir.replace(/\//g, "\\") + _rootnode.name + ".as:" + _rootnode.baseClass.line + ": Error: 不存在" + identnode.word + " " + _rootnode.baseClass.getLine());
						}
						CONFIG::release{
							
							trace(Script.scriptdir.replace(/\//g, "\\") + _rootnode.name + ".as:"  + ": Error: 不存在" + identnode.word + " " );
						
						}
					}
				}
			}
			for each (o in this._rootnode.fields)
			{
				if (o.nodeType != GNodeType.FunDecl)
				{
					this.executeFiledDec(o);
				}
			}
			
			if (this.__rootnode.motheds[this._classname])
			{
				this.call(this._classname, explist);
			}
		}
		
		private function executeFiledDec(node:GNode):void
		{
			if (node.nodeType == GNodeType.AssignStm)
			{
				this.__object[node.childs[0].token.value] = this.getValue(node.childs[1]);
			}
			else if (node.nodeType == GNodeType.VarDecl)
			{
				this.__object[node.word] = node.defValue//getDefValue(node);
			}
		}
		
		//private function getDefValue(node:GNode):Object{
		//	return  node.defValue;
			/*var defvalue:Object=null
				if (node.vartype=="uint"){
					defvalue = 0;
				}else if (node.vartype=="int"){
					defvalue = 0;
				}else if (node.vartype=="Number"){
					defvalue = NaN;
				}else if (node.vartype=="Boolean"){
					defvalue = false;
				}
				return defvalue;*/
		//}
		
		public static function GetDefValue(word:String):Object{
			var defvalue:Object=null
				if (word=="uint"){
					defvalue = 0;
				}else if (word=="int"){
					defvalue = 0;
				}else if (word=="Number"){
					defvalue = NaN;
				}else if (word=="Boolean"){
					defvalue = false;
				}
				return defvalue;
		}
		
		private function get jumpstate():int
		{
			return this.jumpstates[this.jumpstates.length - 1];
		}
		
		private function set jumpstate(v:int):void
		{
			this.jumpstates[this.jumpstates.length - 1] = v;
		}
		
		public function pushstate():void
		{
			this.jumpstates.push(0);
		}
		
		public function popstate():void
		{
			this.jumpstates.pop();
		}
		
		public function call(funcname:String, explist:Array):*
		{
			var node:GNode = null;
			var tisret:Boolean = false;
			var re:* = null;
			
				node = this.__rootnode.motheds[funcname];
				if (node == null)
				{
					if (explist.length)
					{
						node = __rootnode.sets[funcname];
					}
					else
					{
						node = __rootnode.gets[funcname];
					}
				}
				if (Boolean(node) && node.nodeType == GNodeType.FunDecl)
				{
					tisret = this.isret;
					this.isret = false;
					this.local_vars.push({});
					this.__vars = this.local_vars[this.local_vars.length - 1];
					//
					re = this.FunCall(node, explist);
					this.local_vars.pop();
					if (this.local_vars.length > 0)
					{
						this.__vars = this.local_vars[this.local_vars.length - 1];
					}
					else
					{
						this.__vars = null;
					}
					this.isret = tisret;
				}
				else if (this.__object[funcname] is Function)
				{
					re = this.callLocalFunc(this.__object, funcname, explist);
				}
				else
				{
					DY.executeError(this._classname + "的方法:" + funcname + " 未定义");
				}
			
			return re;
		}
		
		private function FunCall(node:GNode, explist:Array):*
		{
			var param:GNode = null;
			var i:int = 0;
			var stms:GNode = null;
			if (node.nodeType == GNodeType.FunDecl)
			{
				
				param = node.childs[0];
				if(param.childs)
				for (i = 0; i < param.childs.length; i++)
				{
					if (explist[i] == null && param.childs[i].childs&&param.childs[i].childs.length)
					{
						var cd:GNode = param.childs[i].childs[0];
						explist[i] = cd.value;
					}
					this.__vars[param.childs[i].word] = explist[i];
				}
				__vars.arguments = explist;
				stms = node.childs[1];
				return this.executeST(node.childs[1]);
			}
		}
		
		public function executeST(node:GNode):*
		{
			/*if (node.executeST){//加上这行100000 次 for循环++，需要时间从1168，减少到1050
				return node.executeST(node,this);
			}*/
			var i:int = 0;
			var re:* = undefined;
			var arr:Array = null;
			var obj:Object = null;
			var lnode:GNode = null;
			var tlvalue:parser.LValue = null;
			var rvalue:* = undefined;
			var cn:GNode = null;
			var exp:* = undefined;
			var jump:Boolean = false;
			var isbreak:Boolean = false;
			var j:int = 0;
			var scope:* = undefined;
			var varname:String = null;
			var o:String = null;
			var oo:* = undefined;
			if (node.nodeType == GNodeType.Stms||node.nodeType==GNodeType.TRY)
			{
				if(node.childs)
				for (i = 0; i < node.childs.length; i++)
				{
					re = this.executeST(node.childs[i]);
					if (this.isret)
					{
						return re;
					}
					if (this.jumpstate > 0)
					{
						return;
					}
				}
			}
			else if (node.nodeType == GNodeType.IDENT)
			{
				//表达式。
				getValue(node);
			}
			else if (node.nodeType == GNodeType.AssignStm)
			{
				lnode = node.childs[0];
				tlvalue = new parser.LValue();
				if (lnode.nodeType == GNodeType.VarDecl)
				{
					if (this.__vars)
					{
						tlvalue.scope = this.__vars;
						tlvalue.key = node.childs[0].word;
					}
					else
					{
						tlvalue.scope = this;
						tlvalue.key = node.childs[0].word;
					}
				}
				else
				{
					this.getLValue(lnode);
					tlvalue.scope = this.lvalue.scope;
					tlvalue.key = this.lvalue.key;
					if (tlvalue.key == null)
					{
						CONFIG::debug{
						throw new Error("左值取值失败=" + lnode.code);
						}
						CONFIG::release{
							throw new Error("左值取值失败=" + lnode.word);
						}
					}
				}
				rvalue = this.getValue(node.childs[1]);
				switch (node.word)
				{
				case "=": 
					tlvalue.scope[tlvalue.key] = rvalue;
					break;
				case "+=": 
					tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] + rvalue;
					break;
				case "-=": 
					tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] - rvalue;
					break;
				case "*=": 
					tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] * rvalue;
					break;
				case "/=": 
					tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] / rvalue;
					break;
				case "%=": 
					tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] % rvalue;
					break;
				case "^=": 
					tlvalue.scope[tlvalue.key] = tlvalue.scope[tlvalue.key] ^ rvalue;
					break;
				}
			}
			else
			{
				if (node.nodeType == GNodeType.IfElseStm)
				{
					i = 0;
					while (true)
					{
						if (node.childs&& i < node.childs.length)
						{
							cn = node.childs[i];
							if (cn.nodeType == GNodeType.ELSEIF)
							{
								exp = this.getValue(cn.childs[0]);
								if (exp)
								{
									re = this.executeST(cn.childs[1]);
									if (this.isret)
									{
										return re;
									}
									if (this.jumpstate > 0)
									{
										return;
									}
									return;
								}
							}
							else
							{
								re = this.executeST(cn);
								if (this.isret)
								{
									break;
								}
								if (this.jumpstate > 0)
								{
									return;
								}
							}
							i++;
							continue;
						}
						else
						{
							break
						}
					}
					return re;
				}
				if (node.nodeType == GNodeType.SWITCH)
				{
					this.pushstate();
					try
					{
						exp = this.getValue(node.childs[0]);
						jump = false;
						isbreak = true;
						for (i = 1; i < node.childs.length; i++)
						{
							if (jump)
							{
								break;
							}
							cn = node.childs[i];
							if (cn.nodeType == GNodeType.CASE)
							{
								if (isbreak == false || Boolean(isbreak) && exp == this.getValue(cn.childs[0]))
								{
									isbreak = false;
									for (j = 1; j < cn.childs.length; j++)
									{
										if ((cn.childs[j] as GNode).nodeType == GNodeType.BREAK)
										{
											jump = true;
											isbreak = true;
											break;
										}
										re = this.executeST(cn.childs[j]);
										if (this.isret)
										{
											return re;
										}
									}
								}
							}
							else if (cn.nodeType == GNodeType.DEFAULT)
							{
								if(cn.childs)
								for (j = 0; j < cn.childs.length; j++)
								{
									if ((cn.childs[j] as GNode).nodeType == GNodeType.BREAK)
									{
										jump = true;
										break;
									}
									re = this.executeST(cn.childs[j]);
									if (this.isret)
									{
										return re;
									}
								}
							}
						}
					}
					finally
					{
						this.popstate();
					}
				}
				else
				{
					if (node.nodeType == GNodeType.INCREMENT)
					{
						return this.onINCREMENT(node);
					}
					if (node.nodeType == GNodeType.PREINCREMENT)
					{
						return this.onPREINCREMENT(node);
					}
					if (node.nodeType == GNodeType.VarDecl)
					{
						scope = this.__vars || this;
						scope[node.word] = node.defValue;//getDefValue(node);
					}
					else
					{
						if (node.nodeType == GNodeType.ReturnStm)
						{
							if (node.childs&&node.childs.length > 0)
							{
								re = this.getValue(node.childs[0]);
								this.isret = true;
								return re;
							}
							this.isret = true;
							return undefined;
						}
						if (node.nodeType == GNodeType.CONTINUE)
						{
							this.jumpstate = 2;
						}
						else if (node.nodeType == GNodeType.BREAK)
						{
							this.jumpstate = 1;
						}
						else if (node.nodeType == GNodeType.WhileStm)
						{
							this.pushstate();
							try
							{
								while (this.getValue(node.childs[0]))
								{
									re = this.executeST(node.childs[1]);
									if (this.isret)
									{
										return re;
									}
									if (this.jumpstate == 1)
									{
										break;
									}
									this.jumpstate = 0;
								}
							}
							finally
							{
								this.popstate();
							}
						}
						else if (node.nodeType == GNodeType.ForStm)
						{
							this.executeST(node.childs[0]);
							this.pushstate();
							try
							{
								while (this.getValue(node.childs[1]))
								{
									re = this.executeST(node.childs[3]);
									if (this.isret)
									{
										return re;
									}
									if (this.jumpstate == 1)
									{
										break;
									}
									this.jumpstate = 0;
									this.executeST(node.childs[2]);
								}
							}
							finally
							{
								this.popstate();
							}
						}
						else if (node.nodeType == GNodeType.ForInStm)
						{
							varname = node.childs[0].word;
							obj = this.getValue(node.childs[1]);
							this.pushstate();
							try
							{
								for (o in obj)
								{
									this.__vars[varname] = o;
									re = this.executeST(node.childs[2]);
									if (this.isret)
									{
										return re;
									}
									if (this.jumpstate == 1)
									{
										break;
									}
									this.jumpstate = 0;
								}
							}
							finally
							{
								this.popstate();
							}
						}
						else if (node.nodeType == GNodeType.ForEACHStm)
						{
							varname = node.childs[0].word;
							obj = this.getValue(node.childs[1]);
							this.pushstate();
							try
							{
								for each (oo in obj)
								{
									this.__vars[varname] = oo;
									re = this.executeST(node.childs[2]);
									if (this.isret)
									{
										return re;
									}
									if (this.jumpstate == 1)
									{
										break;
									}
									this.jumpstate = 0;
								}
							}
							finally
							{
								this.popstate();
							}
						}
						else if (node.nodeType == GNodeType.importStm)
						{
							arr = node.word.split(".");
							this.__API[arr[arr.length - 1]] = Script.getDef(node.word);
						}
					}
				}
			}
		}
		
		public static function OnAssignStm(node:GNode, dy:DY):Number{
			return 0;
		}
		
		public static function OnINCREMENT(node:GNode,dy:DY):Number
		{
			//return dy.onINCREMENT(node);
			//var re:Number = NaN;
			dy.getLValue(node.childs[0]);
			if (dy.lvalue.key != null)
			{
				if (node.word == "++")
				{
					//re = dy.lvalue.scope[dy.lvalue.key];
					return dy.lvalue.scope[dy.lvalue.key]++;// = dy.lvalue.scope[dy.lvalue.key] + 1;
					//return re;
				}
				if (node.word == "--")
				{
					//re = dy.lvalue.scope[dy.lvalue.key];
					return dy.lvalue.scope[dy.lvalue.key]--;// = dy.lvalue.scope[dy.lvalue.key] - 1;
					//return re;
				}
				//dy.executeError("解释出错=递增操作符未设置值");
			}
			return 0;
		}
		
		protected function onINCREMENT(node:GNode):Number
		{
			//var re:Number = NaN;
			this.getLValue(node.childs[0]);
			if (this.lvalue.key != null)
			{
				if (node.word == "++")
				{
					//re = this.lvalue.scope[this.lvalue.key];
					return this.lvalue.scope[this.lvalue.key]++;// = this.lvalue.scope[this.lvalue.key] + 1;
					//return re;
				}
				if (node.word == "--")
				{
					//re = this.lvalue.scope[this.lvalue.key];
					return this.lvalue.scope[this.lvalue.key]--;// = this.lvalue.scope[this.lvalue.key] - 1;
					//return re;
				}
				//this.executeError("解释出错=递增操作符未设置值");
			}
			return 0;
		}
		
		protected function onPREINCREMENT(node:GNode):Number
		{
			this.getLValue(node.childs[0]);
			if (this.lvalue.key != null)
			{
				if (node.word == "++")
				{
					this.lvalue.scope[this.lvalue.key] = this.lvalue.scope[this.lvalue.key] + 1;
					return this.lvalue.scope[this.lvalue.key];
				}
				if (node.word == "--")
				{
					this.lvalue.scope[this.lvalue.key] = this.lvalue.scope[this.lvalue.key] - 1;
					return this.lvalue.scope[this.lvalue.key];
				}
				DY.executeError("解释出错=递增操作符未设置值");
				return this.lvalue.scope[this.lvalue.key];
			}
			return 0;
		}
		
		protected function getLValue(node:GNode):void
		{
			var var_arr:Array = null;
			var i:int = 0;
			var vname:String = null;
			var fristNode:GNode;
			var scope:* = undefined;
			var bottem:int = 0;
			var v:* = undefined;
			var lastv:String = null;
			this.lvalue.scope = null;
			this.lvalue.key = null;
			this.lvalue.params = null;
			if (node.nodeType == GNodeType.IDENT)
			{
				var_arr = [];
				if(node.childs)
				for (i = 0; i < node.childs.length; i++)
				{
					var nc:GNode = node.childs[i];
					if (nc.nodeType == GNodeType.newClass){
						var test:Object = getValue(node.childs[i]);
						nc = new GNode;
						nc.nodeType = GNodeType.ConstID;
						nc.token = new Token;
						nc.token.type = TokenType.constant;
						nc.token.value = test;
						nc.word = "temp";
					}
					
					if (nc.nodeType == GNodeType.Index)
					{
						var_arr.push(this.getValue(nc.childs[0]));
						
					}
					else if (nc.nodeType == GNodeType.FunCall)
					{
						//表达式列表
						var explist:Array = [];
						if (nc.childs&& nc.childs.length > 0)
						{
							var exps:GNode = nc.childs[0];
							if(exps.childs)
							for (var z:int = 0; z < exps.childs.length; z++)
							{
								explist.push(this.getValue(exps.childs[z]));
							}
						}
						var_arr.push(explist);
					}
					else
					{
						if (i == 0)
						{
							fristNode = nc;
						}
						var_arr.push(nc.word);
						
					}
				}
				vname = var_arr[0];
				scope = null;
				//
				/*if (vname == "doAction")
				{
					trace(1);
				}*/
				if (fristNode && fristNode.nodeType == GNodeType.ConstID)
				{
					scope = {};
					scope[vname] = vname;
				}
				else if (vname == "this")
				{
					scope = this;
					var_arr.shift();
				}
				else if (vname == "super")
				{
					scope = this.__super;//有2种情况,一种是调用构造函数
					if (var_arr.length == 2 && node.childs[1].nodeType == GNodeType.FunCall)
					{
						var identnode:Token = __rootnode.baseClass;// GenTree.Branch[__rootnode.baseClass.word].motheds[__rootnode.baseClass];
						if(identnode){
							var arrr = identnode.value.split(".");
							var c = null;
							if (this.__API[arrr[arrr.length - 1]])
							{
								c = this.__API[arrr[arrr.length - 1]];
							}
							else if (Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.value))
							{
								c = Script.getDef(identnode.value) as Class;
							}
							if (parser.GenTree.hasScript(identnode.value))
							{
								__super = new DY(GenTree.Branch[identnode.value], var_arr[1]);
								//trace("成功创建脚本类=" + identnode.word + "的实例");
							}else if (c){
								__super = newLocalClass(c, var_arr[1]);
							}else{
								trace("创建基类失败",identnode.value,_classname);
							}
						}
						return;//特殊情况，直接赋值
					}
					
					var_arr.shift();
				}
				else if (Boolean(this.__vars) && this.__vars[vname] != undefined)
				{
					scope = this.__vars;
				}
				else if (this.hasOwnProperty(vname))
				{
					scope = this;
				}
				else if (this.__static_rootnode && (this.__static_rootnode.motheds[vname] || this.__static_rootnode.fields[vname]))
				{
					//本类的静态方法,指向本类的静态实例
					scope = __static_rootnode.instance;
				}
				else if (this.__API[vname])
				{
					scope = this.__API;
				}
				else if (Script.globalAPI && Script.globalAPI[vname])
				{
					scope = Script.globalAPI;
				}
				else if (__API.hasOwnProperty(vname)&&GenTree.staticBranch[vname]==null&&GenTree.hasScript(vname)&&parser.GenTree.staticBranch[vname]){
					//指向其他静态类
					scope = parser.GenTree.staticBranch[vname].instance;
					var_arr.shift();
				}
				else if (parser.GenTree.staticBranch[vname])
				{
					//指向其他静态类
					scope = parser.GenTree.staticBranch[vname].instance;
					var_arr.shift();
				}
				else if (Script._root && Boolean(Script._root.loaderInfo.applicationDomain.hasDefinition(vname)))
				{
					scope = Script.getDef(vname);
					var_arr.shift();
				}
				if (!scope)
				{
					scope = this.__vars;
				}
				v = scope;
				
				if (v != null)
				{
					for (i = 0; i < var_arr.length - 1; i++)
					{
						if (v != null)
						{
							if (v is Function)
							{
								if (var_arr[i] is Array)
								{
									if (scope is DY)
									{
										v = (v as Function).apply(null, var_arr[i]);
									}
									else
									{
										v = (v as Function).apply(scope, var_arr[i])
									}
									
								}
							}
							else
							{
								scope = v;
								v = v[var_arr[i]];
							}
						}
					}
					if (v != undefined)
					{
						if (v is Function)
						{
							//倒数一层为函数，最后可能为调用，也可能
							this.lvalue.scope = scope;
							this.lvalue.key = var_arr[var_arr.length - 2];
							this.lvalue.params = var_arr[var_arr.length - 1];
							
						}
						else if (i < var_arr.length)
						{
							lastv = var_arr[var_arr.length - 1];
							this.lvalue.scope = v;
							this.lvalue.key = lastv;
							this.lvalue.params = null;
						}
						else
						{
							this.lvalue.scope = v;
						}
					}
				}
			}
		}
		
		public function getValue(node:GNode):*
		{
			/*if (node.getValue){//优化了1/10
				return node.getValue(node, this);
			}*/
			
			var v1:* = undefined;
			var c:Class = null;
			var identnode:GNode = null;
			var arrr:Array = null;
			var re:* = undefined;
			var ident:GNode = null;
			var vname_arr:Array = null;
			var scope:* = undefined;
			var bottom:int = 0;
			var lastvname:String = null;
			var vname:String = null;
			var exps:GNode = null;
			var explist:Array = null;
			var newobj:Object = null;
			var param:GNode = null;
			var i:int = 0;
			var o:* = undefined;
			var loadstatic:Boolean = false;
			switch (node.nodeType)
			{
			case GNodeType.IDENT: 
				this.getLValue(node);
				if (this.lvalue.key != null)
				{
					return this.lvalue.Value;
				}
				else if (this.lvalue.scope)
				{
					return this.lvalue.scope;
				}
				return undefined;
			case GNodeType.VarID: 
				return node.word;
			case GNodeType.ConstID: 
				return node.value;
			case GNodeType.MOP: 
				return this.onMOP(node);
			case GNodeType.LOP: 
				v1 = this.getValue(node.childs[0]);
				if (node.word == "||" || node.word == "or")
				{
					return v1 || this.getValue(node.childs[1]);
				}
				if (node.word == "&&" || node.word == "and")
				{
					return v1 && this.getValue(node.childs[1]);
				}
				break;
			case GNodeType.LOPNot: 
				v1 = this.getValue(node.childs[0]);
				return !v1;
			case GNodeType.Nagtive: 
				v1 = this.getValue(node.childs[0]);
				return -v1;
			case GNodeType.INCREMENT: 
				return this.onINCREMENT(node);
			case GNodeType.PREINCREMENT: 
				return this.onPREINCREMENT(node);
			case GNodeType.COP: 
				return this.onCOP(node);
			case GNodeType.newArray: 
				if (node.childs&& node.childs.length > 0)
				{
					exps = node.childs[0];
					explist = [];
					if(exps.childs)
					for (i = 0; i < exps.childs.length; i++)
					{
						explist[i] = this.getValue(exps.childs[i]);
					}
					return explist;
				}
				return [];
			case GNodeType.newObject: 
				if (node.childs&& node.childs.length > 0)
				{
					newobj = {};
					for (i = 0; i < node.childs.length; i = i + 2)
					{
						newobj[node.childs[i].word] = this.getValue(node.childs[i + 1]);
					}
					return newobj;
				}
				return {};
			case GNodeType.newClass: 
				identnode = node.childs[0];
				//trace("new class-----------",identnode.word);
				arrr = identnode.word.split(".");
				///trace(arrr);
				if (this.__API[arrr[arrr.length - 1]])
				{
					c = this.__API[arrr[arrr.length - 1]];
					//trace("api",c);
				}
				else if (Script._root.loaderInfo.applicationDomain.hasDefinition(identnode.word))
				{
					c = Script.getDef(identnode.word) as Class;
					//trace("getdef",c);
				}
				explist = [];
				if (node.childs&& node.childs.length == 2)
				{
					param = node.childs[1];
					if(param.childs)
					for (i = 0; i < param.childs.length; i++)
					{
						explist[i] = this.getValue(param.childs[i]);
					}
				}
				if (c)
				{
					//trace("newlocalclass",c);
					return newLocalClass(c, explist);
				}
				if (parser.GenTree.hasScript(identnode.word))
				{
					//trace("newdy");
					re = new DY(GenTree.Branch[identnode.word], explist);
					//trace("成功创建脚本类=" + identnode.word + "的实例");
					return re;
				}
				
				trace("new class-----------", identnode.word);
				for (var key:String in __API){
					trace("api:", key, __API[key]);
				}
				
				trace("脚本类=" + identnode.word + "尚未定义");
				return null;
				
			case GNodeType.threeStm: 
				return getValue(node.childs[0]) ? getValue(node.childs[1]) : getValue(node.childs[2]);
			}
		}
		
		protected function onMOP(node:GNode):*
		{
			var v1:* = this.getValue(node.childs[0]);
			var v2:* = this.getValue(node.childs[1]);
			switch (node.word)
			{
			case "^": 
				return v1 ^ v2;
			case "+": 
				return v1 + v2;
			case "-": 
				return v1 - v2;
			case "*": 
				return v1 * v2;
			case "/": 
				return v1 / v2;
			case "%": 
				return v1 % v2;
			case "|": 
				return v1 | v2;
			case "&": 
				return v1 & v2;
			case "<<": 
				return v1 << v2;
			case ">>": 
				return v1 >> v2;
			default: 
				return;
			}
		}
		public static function OnCOP(node:GNode,dy:DY):*
		{
			var v1:* = dy.getValue(node.childs[0]);
			var v2:* = dy.getValue(node.childs[1]);
			switch (node.word)
			{
			case ">": 
				return v1 > v2;
			case "<": 
				return v1 < v2;
			case "<=": 
				return v1 <= v2;
			case ">=": 
				return v1 >= v2;
			case "==": 
				return v1 == v2;
			case "!=": 
				return v1 != v2;
			case "is": 
			case "instanceof": 
				return iS(v1, v2);
			case "as": 
				if (iS(v1, v2))
				{
					return v1;
				}
				return null;
			case "in": 
				return v1 in v2;
			default: 
				return;
			}
		}
		protected function onCOP(node:GNode):*
		{
			var v1:* = this.getValue(node.childs[0]);
			var v2:* = this.getValue(node.childs[1]);
			switch (node.word)
			{
			case ">": 
				return v1 > v2;
			case "<": 
				return v1 < v2;
			case "<=": 
				return v1 <= v2;
			case ">=": 
				return v1 >= v2;
			case "==": 
				return v1 == v2;
			case "!=": 
				return v1 != v2;
			case "is": 
			case "instanceof": 
				return iS(v1, v2);
			case "as": 
				if (iS(v1, v2))
				{
					return v1;
				}
				return null;
			case "in": 
				return v1 in v2;
			default: 
				return;
			}
		}
		
		public static function iS(v1:Object, v2:Object):Boolean{
			if (v1 is DY && v2 is DY)
			{
				//这里有一些脚本类的判断可以做=======
				var n:DY = v1 as DY;
				if (n._classname==(v2 as DY)._classname){
					return true;
				}
				if (n.__super){
					return iS(n.__super,v2);
				}
				return false;
			}
			if (v2 is Class){
				return v1 is (v2 as Class);
			}
			return false;
		}
		
		protected function callLocalFunc(scope:Object, vname:String, explist:Array):*
		{
			if (scope[vname] is Function)
			{
				return (scope[vname] as Function).apply(scope, explist);
			}
			throw new Error(scope + "不存在" + vname + "方法");
		}
		
		public static function newLocalClass(c:Class, explist:Array):*
		{
			var re:* = undefined;
			switch (explist.length)
			{
			case 0: 
				re = new c();
				break;
			case 1: 
				re = new c(explist[0]);
				break;
			case 2: 
				re = new c(explist[0], explist[1]);
				break;
			case 3: 
				re = new c(explist[0], explist[1], explist[2]);
				break;
			case 4: 
				re = new c(explist[0], explist[1], explist[2], explist[3]);
				break;
			case 5: 
				re = new c(explist[0], explist[1], explist[2], explist[3], explist[4]);
				break;
			case 6: 
				re = new c(explist[0], explist[1], explist[2], explist[3], explist[4], explist[5]);
				break;
			case 7: 
				re = new c(explist[0], explist[1], explist[2], explist[3], explist[4], explist[5], explist[6]);
				break;
			case 8: 
				re = new c(explist[0], explist[1], explist[2], explist[3], explist[4], explist[5], explist[6], explist[7]);
				break;
			default: 
				DY.executeError("解析出错=未知的语句" + c + ">" + explist);
			}
			return re;
		}
		
		public static function executeError(str:String):void
		{
			trace("executeError=" + str);
		}
	}
}

package util
{
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import parse.Token;
	import parser.DY;
	import parser.GNode;
	import parser.GenTree;
	import parser.Script;
	
	/**
	 * ascript编译
	 * @author lizhi
	 */
	public class ASC
	{
		public static var version:int = 1;
		public function ASC()
		{
		
		}
		
		public static function encode(tree:GenTree):Object
		{
			var obj:Array = [/*version*/];//version =1;
			var imports:Array = [];
			var fields:Array = [];
			var motheds:Array = [];
			var sets:Array = [];
			var gets:Array = [];
			var innerClasss:Array = [];
			//var nodes:Array = [];
			//var node2index:Dictionary = new Dictionary;
			
			if (tree.baseClass){
				//obj.push(tree.baseClass.type);
				obj.push(tree.baseClass.value);
				//obj.push(tree.baseClass.word);
			}else{
				obj.push(null/*, null, null*/);
			}
			
			for (var o:String in tree.imports)
			{
				imports.push(o);
			}
			for (o in tree.fields)
			{
				fields.push(encodeNode(tree.fields[o]/*,nodes,node2index*/));
			}
			for (o in tree.motheds)
			{
				motheds.push(encodeNode(tree.motheds[o]/*,nodes,node2index*/));
			}
			for (o in tree.sets)
			{
				sets.push(encodeNode(tree.sets[o]/*,nodes,node2index*/));
			}
			for (o in tree.gets)
			{
				gets.push(encodeNode(tree.gets[o]/*,nodes,node2index*/));
			}
			for each(var stree:GenTree in tree.innerClasss){
				innerClasss.push(ASC.encode(stree));
			}
			
			
			obj.push(tree.name, /*tree.Package,*/ tree.callSuper)
			obj.push(imports.length?imports:null);
			obj.push(fields.length?fields:null);
			obj.push(motheds.length?motheds:null);
			obj.push(sets.length?sets:null);
			obj.push(gets.length?gets:null);
			obj.push(innerClasss.length?innerClasss:null);
			//obj.push(nodes.length?nodes:null);
			return obj;
		}
		
		public static function encodeNode(node:GNode/*,nodes:Array,node2index:Dictionary*/):Object{
			/*if (node2index[node]!=null){
				return node2index[node];
			}*/
			var obj:Array = [];
			//var ret:int = nodes.length;
			//node2index[node] = ret;
			//nodes.push(obj);
			obj.push(/*node.name, *//*node.funtype,*/ node.nodeType,false /*node.istatic*/, node.defValue, node.word);
			if (node.token){
				if (node.token.value==node.word){//如果word 和token.value相等，删除节省体积
					obj[obj.length - 1] = null;
				}
				obj.push(node.token.value);
				//obj.push(/*node.token.type,*/node.token.value/*,node.token.word*/);
			}else{
				obj.push(null/*,null*/);
			}
			if (node.childs&&node.childs.length){
				var childs:Array = obj//[];
				//obj.push(childs);
				for each(var c:GNode in node.childs){
					childs.push(encodeNode(c/*,nodes,node2index*/));
				}
			}
			return obj;
			//return nodes[ret];
			//return ret;
		}
		
		public static function decodeNode(obj:Object/*index:int,nodes:Array,index2node:Object*/):GNode{
			/*if (index2node[index]!=null){
				return index2node[i];
			}
			var obj:Array = nodes[index];*/
			var node:GNode = new GNode;
			//index2node[index] = node;
			var i:int = 0;
			//node.name = obj[i++];
			//node.funtype = obj[i++];
			node.nodeType = obj[i++];
			/*node.istatic = obj[*/i++/*]*/;
			node.defValue = /*DY.GetDefValue(*/obj[i++]/*)*/;
			if (node.defValue is String){
				node.defValue = DY.GetDefValue(node.defValue as String);
			}
			node.word = obj[i++];
			
			if (obj[i] != null){
				var tk:Token = new Token;
				node.token = tk;
				//tk.type = obj[i++];
				tk.value = obj[i++];
				//tk.word = obj[i++];
				if (node.word==null&&tk.value is String){
					node.word = tk.value;
				}
				
			}else{
				i ++;
			}
			
			for (; i < obj.length; i++ ){
				if (node.childs==null){
					node.childs = new Vector.<parser.GNode>();
				}
				/*var ci:int = obj[i];*/
				node.childs.push(decodeNode(obj[i]/*ci,nodes,index2node*/));
			}
			/*if (obj[i]!=null){
				for (){
					
				}
				var childs:Array = obj[i];
				for each(var ci:int in childs){
					node.childs.push(decodeNode(ci,nodes,index2node));
				}
			}*/
			return node;
		}
		
		public static function decodeWithSecureMap(obj:Object, secureMap:Object, depth:int):Object{
			//return JSON.parse(JSON.stringify(obj));
			
			if (obj is String){
				if (secureMap[obj] is String){
					return secureMap[obj];
				}
				return obj;
			}
			
			if (obj==null||obj is Number||obj is int||obj is Boolean){
				return obj;
			}
			if (obj is Array){
				var newobj:Object = [];
				for (var i:int = 0; i < obj.length; i++ ){
					if (i == 3&&depth==1){
						//import
						var ims:Array = obj[i] as Array;
						if (ims){
							var newims:Array = [];
							for (var j:int = 0; j < ims.length;j++ ){
								var str:String = ims[j];
								if (str){
										//trace(1);
										var ii:int = str.lastIndexOf(".");
										if (ii!=-1){
											var a:String = str.substr(0, ii);
											var b:String = str.substr(ii + 1);
											str=decodeWithSecureMap(a, secureMap, depth + 1)+"."+decodeWithSecureMap(b, secureMap, depth + 1);
										}else{
											str=decodeWithSecureMap(str, secureMap, depth + 1) as String;
										}
									//}
									/*var strs:Array = str.split(".");
									for (var k:int = 0; k < strs.length;k++ ){
										strs[k] = decodeWithSecureMap(strs[k], secureMap, depth + 1);
									}*/
									newims[j] = str;////strs.join(".");
								}
							}
							newobj[i]= newims;
						}else{
							newobj[i]= decodeWithSecureMap(obj[i],secureMap,depth+1);
						}
					}else if (i == 8 && depth == 1){
						if (obj[i]){
							newobj[i]= decodeWithSecureMap(obj[i],secureMap,depth-1);
						}else{
							newobj[i] = null;
						}
					}else{
						newobj[i] = decodeWithSecureMap(obj[i],secureMap,depth+1);
					}
				}
				return newobj;
			}
			newobj = {};
			for (var key:String in obj){
				var newkey:Object = decodeWithSecureMap(key,secureMap,depth+1);
				newobj[newkey]=decodeWithSecureMap(obj[key],secureMap,depth+1);
			}
			return newobj;
			/*var oo:Object = {};
			trace(oo is Object);
			var oo2:String = "fdsfds";
			trace(oo2 is Object);
			var oo3:Object = null;
			trace(oo3 is Object);
			var oo4:Object = 1;
			trace(oo4 is Object);
			trace(typeof oo, typeof oo2, typeof oo3, typeof oo4);
			return  obj;
			/*if (obj==null){
				
			}
			var newobj:Object = (obj is Array)?[]:{};*/
		}
		
		public static function decode(obj:Object):GenTree
		{
			//if (obj[0]!=version){
			//	return null;
			//}
			var i:int = 0;
			var tree:GenTree = new GenTree;
			
			if (obj[i]!=null){
				tree.baseClass = new Token;
				//tree.baseClass.type = obj[i++];
				tree.baseClass.value = obj[i++];
				//tree.baseClass.word = obj[i++];
			}else{
				i ++;
			}
			
			tree.name = obj[i++];
			//tree.Package = obj[i++];
			tree.callSuper = obj[i++];
			var imports:Array = obj[i++];
			var fields:Array = obj[i++];
			var motheds:Array = obj[i++];
			var sets:Array = obj[i++];
			var gets:Array = obj[i++];
			var innerClasss:Array = obj[i++];
			
			//if(imports)
			for each(var s:String in imports){
				var di:int = s.lastIndexOf(".");
				var vname:String = s;
				if (di!=-1){
					vname = s.substr(di + 1);
					//GenTree.GAPI[vname] = s.replace(/\./g, "/");
				}else{
					//GenTree.GAPI[vname] = vname;
				}
				tree.imports[s] = true;
				tree.API[vname] = Script.getDef(s);
			}
			//if(fields)
			for each(var v:Object in fields){
				var n:GNode = decodeNode(v/*, nodes, index2node*/);
				tree.fields[n.name] = n;
			}
			//if(motheds)
			for each(var v:Object in motheds){
				var n:GNode = decodeNode(v/*, nodes, index2node*/);
				tree.motheds[n.name] = n;
			}
			//if(sets)
			for each(var v:Object in sets){
				var n:GNode = decodeNode(v/*, nodes, index2node*/);
				tree.sets[n.name] = n;
			}
			if (innerClasss){
				tree.innerClasss = [];
			}
			for each(var obj:Object in innerClasss){
				tree.innerClasss.push(decode(obj));
			}
			//if(gets)
			for each(var v:Object in gets){
				var n:GNode = decodeNode(v/*, nodes, index2node*/);
				tree.gets[n.name] = n;
			}
			return tree;
		}
	}

}
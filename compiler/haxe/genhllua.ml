(*
 *  Haxe Compiler
 *  Copyright (c)2008 Russell Weir
 *  based on and including code by (c)2005-2008 Nicolas Cannasse
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)
open Type
open Ast

type ctx = {
	ch : out_channel;
	path : module_path;
	mutable buf : Buffer.t;
	mutable bufstack : Buffer.t list;
	mutable imports : (string,string list list) Hashtbl.t;
	mutable required_paths : (string list * string) list;
	mutable s_prototype : (string * string) list;
	mutable s_statics : (string * string) list;
	mutable curclass : tclass;
	mutable statics : (tclass * string * texpr) list;
	mutable inits : texpr list;
	mutable tabs : string;
	mutable in_value : bool;
	mutable in_constructor : bool;
	mutable in_function : bool;
	mutable in_static : bool;
	mutable handle_break : bool;
	mutable id_counter : int;
	debug : bool;
	mutable curmethod : (string * bool);
	commentcode : bool;
}

let rec register_required_path ctx path = match path with
	| [], "Float"
	| [], "Int"
	| [], "Array"
	| [], "String"
	| ["lua"], "LuaMath__"
	| ["lua"], "LuaDate__"
	| ["lua"], "LuaXml__"
	| [], "Dynamic"
	| [], "Bool" -> ()
	| _, _ ->
		if not (List.exists(fun p -> p = path) ctx.required_paths) then
			ctx.required_paths <- path :: ctx.required_paths

let rec register_prototype ctx name value =
	let v = (name,value) in
	if not (List.exists(fun p -> p = v) ctx.s_prototype) then
		ctx.s_prototype <- v :: ctx.s_prototype

let rec register_static ctx name value =
	let v = (name,value) in
	if not (List.exists(fun p -> p = v) ctx.s_statics) then
		ctx.s_statics <- v :: ctx.s_statics

let init dir path =
	let rec create acc = function
		| [] -> ()
		| d :: l ->
			let dir = String.concat "/" (List.rev (d :: acc)) in
			if not (Sys.file_exists dir) then Unix.mkdir dir 0o755;
			create (d :: acc) l
	in
	let dir = dir :: fst path in
	create [] dir;
	let ch = open_out (String.concat "/" dir ^ "/" ^ snd path ^ ".lua") in
	let imports = Hashtbl.create 0 in
	Hashtbl.add imports (snd path) [fst path];
	{
		ch = ch;
		path = path;
		buf = Buffer.create (1 lsl 14);
		bufstack = [];
		imports = imports;
		required_paths = [];
		s_prototype = [];
		s_statics = [];
		statics = [];
		inits = [];
		curclass = null_class;
		tabs = "";
		in_value = false;
		in_constructor = false;
		in_function = false;
		in_static = false;
		handle_break = false;
		debug = Plugin.defined "debug";
		id_counter = 0;
		curmethod = ("",false);
		commentcode = false;
	}

let close ctx =
	output_string ctx.ch "module(\"";
	(match (fst ctx.path) with
		| [] -> ()
		| _ ->
			output_string ctx.ch (Printf.sprintf "%s." (String.concat "." (fst ctx.path)))
	);
	output_string ctx.ch ( snd ctx.path ^ "\", package.seeall)\n" );

	(* register imports as required_paths *)
	Hashtbl.iter (fun name paths ->
		List.iter (fun pack ->
			let path = pack, name in
			register_required_path ctx path
		) paths
	) ctx.imports;

	(* write out required_paths *)
	List.iter (fun path ->
		if path <> ctx.path then output_string ctx.ch ("require \"" ^ Ast.s_type_path path ^ "\";\n");
	) ctx.required_paths;
	output_string ctx.ch (Printf.sprintf "\n" );

	(* write out body *)
	output_string ctx.ch (Buffer.contents ctx.buf);

	(* write out prototype values *)
	output_string ctx.ch "\n\n--- prototype decl ---\n";
	List.iter (fun (name,value) ->
		output_string ctx.ch ("prototype['" ^ name ^ "'] = "^value^";\n");
	) ctx.s_prototype;

	(* write out prototype values *)
	output_string ctx.ch "\n--- statics decl ---\n";
	List.iter (fun (name,value) ->
		output_string ctx.ch ("__statics__['" ^ name ^ "'] = "^value^";\n");
	) ctx.s_statics;
	output_string ctx.ch "\n";

	close_out ctx.ch

let rec s_tclass_kind mtclass =
	match mtclass.cl_kind with
	| KNormal -> "KNormal"
	| KTypeParameter -> "KTypeParameter"
	| KExtension (tc,_) ->
		(Printf.sprintf "KExtension of %s" (s_tclass_kind tc))
	| KConstant (tc) ->
		(match tc with
		| TInt _ -> "KConstant TInt"
		| TFloat _ -> "KConstant TFloat"
		| TString _ -> "KConstant TString"
		| TBool _ -> "KConstant TBool"
		| TNull -> "KConstant TNull"
		| TThis -> "KConstant TThis"
		| TSuper -> "KConstant TSuper"
		)
	| KGeneric -> "KGeneric"
	| KGenericInstance _ -> "KGenericInstance"

let s_path1 = function
	| ([],"@Main") -> "Main"
	| p -> Ast.s_type_path p

let s_path ctx path isextern p =
	if not isextern then register_required_path ctx path;
	match path with
	| ([],name) ->
		(match name with
(* 		| "List" -> "HList" *)
		| _ -> name)
(*	| (["lua"],"LuaArray__") ->
		"Array"*)
	| (["lua"],"LuaDate__") ->
		"Date"
	| (["lua"],"LuaMath__") ->
		"Math"
	| (["lua"],"LuaString__") ->
		"String"
	| (["lua"],"LuaXml__") ->
		"Xml"
	| (pack,name) ->
		try
		(match Hashtbl.find ctx.imports name with
		| [p] when p = pack ->
			String.concat "." pack ^ "." ^ name
		| packs ->
			if not (List.mem pack packs) then Hashtbl.replace ctx.imports name (pack :: packs);
			Ast.s_type_path path)
		with Not_found ->
			Hashtbl.add ctx.imports name [pack];
			String.concat "." pack ^ "." ^ name

let kwds =
	let h = Hashtbl.create 0 in
	List.iter (fun s -> Hashtbl.add h s ()) [
		"and"; "break"; "do"; "continue"; "else"; "elseif";
		"end"; "false"; "for"; "function"; "if";
		"in"; "local"; "nil"; "not"; "or"; "repeat";
		"return"; "then"; "true"; "until"; "while"; "*name";
		"*number"; "*string"; "<eof>"
	];
	h


let member s = ":" ^ s
let staticfield s = if Hashtbl.mem kwds s then "[\"" ^ s ^ "\"]" else "." ^ s
let ident s = if Hashtbl.mem kwds s then "___" ^ s else s

let fieldaccess mem =
	match mem with
	| true -> ":"
	| false -> "."

(*
Neko version
let ident p s =
	let l = String.length s in
	if l > 7 && String.sub s 0 7 = "__lua__" then
		(EConst (Builtin (String.sub s 7 (l - 7))),p)
	else
		(EConst (Ident s),p)
*)
let s_ident n =
	match n with
	| "is" -> "is"
	| "as" -> "as"
	| "int" -> "int"
	| "const" -> "const"
	| "getTimer" -> "getTimer"
	| "typeof" -> "typeof"
	| "parseInt" -> "parseInt"
	| "parseFloat" -> "parseFloat"
	| "type" -> "_type"
	| "end" -> "_end"
	| _ -> n

let spr ctx s = Buffer.add_string ctx.buf s
let print ctx = Printf.kprintf (fun s -> Buffer.add_string ctx.buf s)
let unsupported = Typer.error "This expression cannot be compiled to Lua"
let newline ctx =
	match Buffer.nth ctx.buf (Buffer.length ctx.buf - 1) with
	| 'd' ->
		(match Buffer.sub ctx.buf (Buffer.length ctx.buf - 3) 3 with
		| "end" -> print ctx "\n%s" ctx.tabs
		| _ -> print ctx "\n%s" ctx.tabs
		);
	| 'o' ->
		(match Buffer.sub ctx.buf (Buffer.length ctx.buf - 2) 2 with
		| "do" -> print ctx "\n%s" ctx.tabs
		| _ -> print ctx "\n%s" ctx.tabs
		);
	| _ -> print ctx ";\n%s" ctx.tabs


let carriagereturn ctx =
	print ctx "\n%s" ctx.tabs

let commentcode ctx s =
	match ctx.commentcode with
	| true ->
		print ctx "-- %s" s;
		carriagereturn ctx;
	| false -> ()

let s_type_name e =
  s_type (print_context()) e.etype

let is_array_type e =
  let s = s_type_name e in
  if String.length s > 4 && String.sub s 0 5 = "Array" then true else false

let is_string_type e =
  if (s_type_name e) = "String" then true else false

let is_constant e =
	match e with
	| TConst _ -> true
	| _ -> false
(*
prefix ++
(function() r = r + 1; return r; end)()
postfix ++
(function() local __ = r; r = r + 1; return __; end)()
prefix --
(function() r = r - 1; return r; end)()
postfix --
(function() local __ = r; r = r - 1; return __; end)()

http://lua-users.org/wiki/TernaryOperator

	e++ -> (e = e + 1)
*)
let unop_string post adding repl =
	match post with
	| true ->
		(match adding with
		| true ->  Printf.sprintf "(function() local _ = %s; %s = %s + 1; return _; end)()" repl repl repl
		| false ->  Printf.sprintf "(function() local _ = %s; %s = %s - 1; return _; end)()" repl repl repl
		);
	| false ->
		(match adding with
		| true ->  Printf.sprintf "(function() %s = %s + 1; return %s; end)()" repl repl repl
		| false ->  Printf.sprintf "(function() %s = %s - 1; return %s; end)()" repl repl repl
		);
	;;

let rec s_binop = function
	| OpAdd -> "+"
	| OpMult -> "*"
	| OpDiv -> "/"
	| OpSub -> "-"
	| OpAssign -> "="
	| OpEq -> "=="
	| OpPhysEq -> "=="
	| OpNotEq -> "~="
	| OpPhysNotEq -> "~="
	| OpGte -> ">="
	| OpLte -> "<="
	| OpGt -> ">"
	| OpLt -> "<"
	| OpAnd -> "&"
	| OpOr -> "|"
	| OpXor -> "^|"
	| OpBoolAnd -> "and"
	| OpBoolOr -> "or"
	| OpShr -> ">>"
	| OpUShr -> ">>>"
	| OpShl -> "<<"
	| OpMod -> "%"
	| OpAssignOp op -> "" ^ s_binop op ^ ""
	| OpInterval -> "..."


let rec concat ctx s f = function
	| [] -> ()
	| [x] -> f x
	| x :: l ->
		f x;
		spr ctx s;
		concat ctx s f l

let block = Transform.block

let fun_block ctx f =
	if ctx.debug then
		Transform.stack_block (ctx.curclass,fst ctx.curmethod) f.tf_expr
	else
		block f.tf_expr

let parent e =
	match e.eexpr with
	| TParenthesis _ -> e
	| _ -> mk (TParenthesis e) e.etype e.epos

let open_block ctx =
	let oldt = ctx.tabs in
	ctx.tabs <- "\t" ^ ctx.tabs;
	(fun() -> ctx.tabs <- oldt)

let push_buf ctx =
	let oldbuf = ctx.buf in
	ctx.bufstack <- oldbuf :: ctx.bufstack;
	ctx.buf <- Buffer.create (512)

let pop_buf ctx =
	let oldbuf = ctx.buf in
	ctx.buf <- (
	match ctx.bufstack with
	| [] -> raise Exit;
	| [e] -> e;
	| e :: el -> e
	);
	Buffer.contents oldbuf

let temp_ctx_buf ctx =
	let oldbuf = ctx.buf in
	ctx.buf <- Buffer.create 500;
	(fun() -> ctx.buf <- oldbuf)

let rec iter_switch_break in_switch e =
	match e.eexpr with
	| TFunction _ | TWhile _ | TFor _ -> ()
	| TSwitch _ | TMatch _ when not in_switch -> iter_switch_break true e
	| TBreak when in_switch -> raise Exit
	| _ -> iter (iter_switch_break in_switch) e

(*
	Checks if an expression has an embedded assignment operator.
	The following syntax is not supported in lua:
	return a = b
	a = b = 3
*)
let rec has_assign_op e =
	match e.eexpr with
	| TBinop (op,e1,e2) ->
		(match op with
		| OpAssignOp o -> raise Exit;
		| OpAssign -> raise Exit;
		| _ ->
			iter (has_assign_op) e1;
			iter (has_assign_op) e2;
			()
		);
(*	| TIf (cond, e, eelse) -> raise Exit;*)
	| TFunction f -> ()
	| _ -> iter (has_assign_op) e

let handle_break ctx e =
	let old_handle = ctx.handle_break in
	try
		iter_switch_break false e;
		ctx.handle_break <- false;
		(fun() -> ctx.handle_break <- old_handle)
	with
		Exit ->
			spr ctx "try ";
			let b = open_block ctx in
			carriagereturn ctx;
			ctx.handle_break <- true;
			(fun() ->
				b();
				ctx.handle_break <- old_handle;
				newline ctx;
				spr ctx " catch e do if e.error ~= nil and e.error != \"__break__\" then throw(e) end end";
			)

let this ctx =
	if ctx.in_constructor then "___new" else
		if ctx.in_value then "this" else if ctx.in_function then "this" else "self"

let gen_constant ctx p = function
	| TInt i -> print ctx "%ld" i
	| TFloat s -> spr ctx s
	| TString s ->
		print ctx "\"%s\"" (Ast.s_escape s)
	| TBool b -> spr ctx (if b then "true" else "false")
	| TNull -> spr ctx "nil"
	| TThis -> spr ctx (this ctx)
	| TSuper -> assert false

let is_method ctx t s =
	match follow t with
	| TInst(c,_) ->
		true
	| _ ->
		false



let extract_field fields name =
	List.find (fun f ->
		match f with
		| (fname, _) when fname = name -> true
		| _ -> false
	) fields

let rec gen_call ctx e el =
	match e.eexpr , el with
	| TConst TSuper , params ->
		(match ctx.curclass.cl_super with
		| None -> assert false
		| Some (c,_) ->
			commentcode ctx "gen_call TConst TSuper";
			print ctx "%s.new(" (s_path ctx c.cl_path true e.epos);
			concat ctx "," (gen_value ctx) params;
			spr ctx ")";
		);
	| TField ({ eexpr = TConst TSuper },name) , params ->
		(match ctx.curclass.cl_super with
		| None -> assert false
		| Some (c,_) ->
			commentcode ctx "gen_call TField TConst TSuper";
(* 			member method super call *)
			print ctx "%s%s(" (s_path ctx c.cl_path true e.epos) (staticfield name);
			concat ctx "," (gen_value ctx) params;
			spr ctx ")"
		);
	(*
		Calls to static string values, ie:
		var s = "abcdef".substr(0,3)
	*)
	| TField ({ eexpr = TConst (TString s)}, name), el  ->
		commentcode ctx "gen_call TFIELD TCONST";
		print ctx "string.haxe_%s(\"%s\"," name s;
		concat ctx "," (gen_value ctx) el;
		spr ctx ")"
	| TField ({ etype = TDynamic (_)}, name), params  ->
(*	| TField (({ eexpr = TField(x,s), etype = TDynamic (_)}), name), params  ->*)
(* 	| TField ({ eexpr = TField(x,s)}, name), params  when e.etype = TDynamic _ -> *)
		commentcode ctx "gen_call TField TDynamic";
		spr ctx "Haxe.callMethod(";
		(match e.eexpr with
		| TField(x,s) -> gen_value ctx x
		| _ -> unsupported e.epos
		);
		print ctx ", \"%s" name;
		spr ctx "\", {";
		concat ctx "," (gen_value ctx) params;
		spr ctx "})"
	| TField (e,s) , el ->
(* 		| TField of texpr * string *)
		commentcode ctx "gen_call TField (e,s)";
		gen_value ctx e;
		(* spr ctx (staticfield s); *)
		let is_func = is_method ctx e.etype s in
		gen_field_access ctx (not is_func) e.etype s;
		spr ctx "(";
		concat ctx "," (gen_value ctx) el;
		spr ctx ")"
	| TCall (x,_) , el when x.eexpr <> TLocal "__lua__" ->
		commentcode ctx "gen_call TCall (x,_)";
		spr ctx "(";
		gen_value ctx e;
		spr ctx ")";
		spr ctx "(";
		concat ctx "," (gen_value ctx) el;
		spr ctx ")";
	| TLocal "__new__" , { eexpr = TConst (TString cl) } :: params ->
		print ctx "%s:new(" cl;
		concat ctx "," (gen_value ctx) params;
		spr ctx ")";
	| TLocal "__new__" , e :: params ->
		gen_value ctx e;
		spr ctx ":new ";
		spr ctx "(";
		concat ctx "," (gen_value ctx) params;
		spr ctx ")";
	| TLocal "__keys__", [e] ->
		print ctx "Haxe.tableKeysArray(";
		gen_value ctx e;
		spr ctx ")";
	| TLocal "__hasOwnProperty__" , e :: params ->
		spr ctx "Haxe.hasOwnProperty ";
		spr ctx "(";
		gen_value ctx e;
		spr ctx ", ";
		concat ctx "," (gen_value ctx) params;
		spr ctx ")";
	| TLocal "__typeof__", [e] ->
		spr ctx "type(";
		gen_value ctx e;
		spr ctx ")";
	| TLocal "__delete__", [e;f] ->
		gen_value ctx e;
		spr ctx "['";
		gen_value ctx f;
		spr ctx "']";
		spr ctx " = nil";
	| TLocal "__tostring__", [e] ->
		spr ctx "_G.tostring(";
		gen_value ctx e;
		spr ctx ")";
	| TLocal "__mkglobal__", [{ eexpr = TConst (TString name) };{ eexpr = TConst (TString value) }] ->
		spr ctx "_G.";
		spr ctx name;
		spr ctx " = ";
		spr ctx value;
	| TLocal "__lua__", [{ eexpr = TConst (TString code) }] ->
		spr ctx code
	| _ ->
		commentcode ctx "gen_call default";
		gen_value ctx e;
		spr ctx "(";
		concat ctx "," (gen_value ctx) el;
		spr ctx ")"

and capture_var ctx e =
	push_buf ctx;
	gen_value ctx e;
	pop_buf ctx

and gen_value_op ctx e =
	match e.eexpr with
	| TBinop (op,_,_) when op = Ast.OpAnd || op = Ast.OpOr || op = Ast.OpXor ->
		spr ctx "(";
		gen_value ctx e;
		spr ctx ")";
	| _ ->
		gen_value ctx e

and gen_assign_if ctx var op cond etrue efalse =
	print ctx "try %s %s " var (s_binop op);
	gen_value ctx cond;
	spr ctx " and ";
	gen_value ctx etrue;
	spr ctx " or throw \"default\" catch e do if e.error==\"default\" then ";
	print ctx "%s %s " var (s_binop op);
	(match efalse with
	| None -> unsupported etrue.epos;
	| Some e when e.eexpr = TConst(TNull) ->
		spr ctx "nil";
	| Some e ->
		gen_value ctx e;
	);
	spr ctx " end end"

(* context Type.t fieldname *)
and gen_field_access ctx isvar t s =
	let field c ismember =
		match fst c.cl_path, snd c.cl_path with
		| [], "Math"
		-> 	 print ctx ".%s" (s_ident s)
		| [], "String"
		->	(match s with
			| "length" -> print ctx ":len()"
			| _ -> print ctx ":haxe_%s" s
			);
		| [], "Array"
		-> (match s with
			| "length" ->
				print ctx ".length"
(*			| "toString" ->
				print ctx ":toString"*)
			| _ ->
				print ctx "%s%s" (fieldaccess ismember) s
			);
		| _ ->
			commentcode ctx (Printf.sprintf "gen_field_access %s %s" s (match ismember with true->"true" | false->"false"));
			print ctx "%s%s" (fieldaccess ismember) (s_ident s)
	in
	match follow t with
	| TInst (c,_) ->
		commentcode ctx (Printf.sprintf "%s" (s_tclass_kind c));
		(match isvar with
		| true->
			commentcode ctx (Printf.sprintf "TInst %s true" s);
			field c false
		| false ->
			commentcode ctx (Printf.sprintf "TInst %s false" s);
			field c true
		)
	| TAnon a ->
		(match !(a.a_status) with
		| Statics c ->
			commentcode ctx "TAnon static";
			field c false
		| _ ->
			commentcode ctx "TAnon unmatched";
			print ctx "%s%s" (if isvar then "." else ":")(s_ident s)
		)
	| TDynamic td ->
		commentcode ctx "gen_field_access TDynamic";
		print ctx ".%s" (s_ident s)
	| _ ->
		commentcode ctx "gen_field_access unmatched";
		print ctx ".%s" (s_ident s)

and gen_expr ctx e =
	match e.eexpr with
	| TConst c ->
		commentcode ctx "gen_expr TConst";
		gen_constant ctx e.epos c
	| TLocal s ->
		commentcode ctx "gen_expr TLocal";
		spr ctx (ident s)
	| TEnumField (en,s) ->
		commentcode ctx "gen_expr TEnumField";
		print ctx "%s.%s" (s_path ctx en.e_path en.e_extern e.epos) s
	| TArray ({ eexpr = TLocal "__global__" },{ eexpr = TConst (TString s) }) ->
		commentcode ctx "gen_expr TArray 1";
		let path = (match List.rev (ExtString.String.nsplit s ".") with
			| [] -> assert false
			| x :: l -> List.rev l , x
		) in
		spr ctx (s_path1 path)
	| TArray (e1,e2) ->
		commentcode ctx "gen_expr TArray 2";
		gen_value ctx e1;
		spr ctx "[";
		gen_value ctx e2;
		spr ctx "]";
	| TBinop (op,{ eexpr = TField (e1,s) },e2) ->
		(match op with
		| OpAssignOp o ->
			commentcode ctx "OpAssignOpa";
			gen_value_op ctx e1;
			gen_field_access ctx true e1.etype s;
			print ctx " = ";
			commentcode ctx "OpAssignOp1b";
			gen_value_op ctx e1;
			gen_field_access ctx true e1.etype s;
			print ctx " %s " (s_binop op);
			print ctx "(";
			gen_value_op ctx e2;
			print ctx ")";
		| _ ->
			commentcode ctx "TBinop (op,{ eexpr = TField (e1,s) },e2) a";
			gen_value_op ctx e1;
			gen_field_access ctx true e1.etype s;
			print ctx " %s " (s_binop op);
			commentcode ctx "TBinop (op,{ eexpr = TField (e1,s) },e2) b";
			gen_value_op ctx e2;
		)
	| TBinop (op,e1,e2) ->
		(match op with
		| OpAssignOp o ->
			commentcode ctx "OpAssignOp2 (unary assign)";
			gen_value_op ctx e1;
			print ctx " = ";
			gen_value_op ctx e1;
			print ctx " %s " (s_binop op);
			print ctx "(";
			gen_value_op ctx e2;
			print ctx ")";
		| _ ->
			commentcode ctx "OpAssignOp2 case 2";
			(match e2.eexpr with
(*			| TIf (cond, etrue, efalse) ->
				spr ctx "try ";
				gen_value_op ctx e1;
				print ctx " %s "  (s_binop op);
				gen_value ctx cond;
				spr ctx " and ";
				gen_value ctx etrue;
				spr ctx " or throw \"default\" catch e do if e.error==\"default\" then ";
				gen_value_op ctx e1;
				print ctx " %s " (s_binop op);
				(match efalse with
				| None -> unsupported e2.epos;
				| Some e when e.eexpr = TConst(TNull) ->
					spr ctx "nil";
				| Some e ->
					gen_value ctx e;
				);
				spr ctx " end end";*)
			| _ ->
				gen_value_op ctx e1;
				print ctx " %s " (s_binop op);
				gen_value_op ctx e2;
			);
		)
	| TField (x,s) ->
		commentcode ctx "gen_expr TField";
		(match follow e.etype with
		| TFun _ ->
			spr ctx "Haxe.closure("; (* closure *)
			gen_value ctx x;
			spr ctx ",";
			gen_constant ctx e.epos (TString s);
			spr ctx ")";
		| _ ->
			(* Check for { var="val"}.var *)
			(match x.eexpr with
			| TObjectDecl fields ->
				(try
					let (s,f) = extract_field fields s in
					gen_value ctx f;
				with
					Exit -> unsupported e.epos;)
			| _ ->
				commentcode ctx "TField (x,s)";
				gen_value ctx x;
				gen_field_access ctx true x.etype s;
			);
		)
	| TTypeExpr t ->
		commentcode ctx "gen_expr TTypeExpr";
		spr ctx (s_path ctx (t_path t) false e.epos)
	| TParenthesis e ->
		spr ctx "(";
		gen_value ctx e;
		spr ctx ")";
	| TReturn eo ->
		commentcode ctx "gen_expr TReturn";
		if ctx.in_value then unsupported e.epos;
		(match eo with
		| None ->
			spr ctx "do return end"
		| Some e ->
			try
				has_assign_op e;
				(match e.eexpr with
				| TIf (cond, etrue, efalse) ->
					let id = ctx.id_counter in
					ctx.id_counter <- ctx.id_counter + 1;
					spr ctx "do";
					let bend1 = open_block ctx in
					carriagereturn ctx;
					print ctx "local null%d" id;
					newline ctx;
					spr ctx "if ";
					gen_value ctx cond;
					print ctx " then null%d = " id;
					gen_value ctx etrue;
					(match efalse with
					| None -> ()
					| Some e when e.eexpr = TConst(TNull) -> ()
					| Some e ->
						newline ctx;
						print ctx "else null%d =" id;
						gen_value ctx e;
					);
					newline ctx;
					spr ctx "end";
					newline ctx;
					print ctx "return null%d" id;
					bend1();
					carriagereturn ctx;
					print ctx "end"
				| _ ->
					spr ctx "do return ";
					gen_value ctx e;
					spr ctx " end"
				);
			with
				Exit -> unsupported e.epos;
(* 				print ctx "do return %s end" (); *)
		);
	| TBreak ->
(* 		if ctx.in_value then unsupported e.epos; *)
		if ctx.handle_break then spr ctx "throw \"__break__\"" else spr ctx "break"
	| TContinue ->
		if ctx.in_value then unsupported e.epos;
		spr ctx "if true then continue end"
	| TBlock [] ->
(*  		spr ctx "-- gen_expr TBlock [] nil"; *)
		spr ctx "collectgarbage(\"step\")";
	| TBlock el ->
		print ctx "do";
		let bend = open_block ctx in
		List.iter (fun e -> newline ctx; gen_expr ctx e) el;
		bend();
		newline ctx;
		print ctx "end";
	| TFunction f ->
		commentcode ctx "gen_expr TFunction";
		let old = ctx.in_value in
		let old_meth = ctx.curmethod in
		let old_infunc = ctx.in_function in
		ctx.in_value <- false;
		if snd ctx.curmethod then begin
			ctx.curmethod <- (fst ctx.curmethod ^ "@" ^ string_of_int (Lexer.get_error_line e.epos), true);
			print ctx "(function ";
			ctx.in_function <- true;
		end
		else
			ctx.curmethod <- (fst ctx.curmethod, true);
		print ctx "(%s) " (String.concat "," (List.map ident (List.map arg_name f.tf_args)));
 		carriagereturn ctx;
		gen_expr ctx (fun_block ctx f);
		if ctx.in_function then begin
			newline ctx;
			print ctx "end)";
		end;
		ctx.in_function <- old_infunc;
		ctx.curmethod <- old_meth;
		ctx.in_value <- old;
	| TCall (e,el) ->
		commentcode ctx "gen_expr TCall";
		gen_call ctx e el
	| TArrayDecl el ->
		spr ctx "Array:new({";
		concat ctx "," (gen_value ctx) el;
		spr ctx "})"
	| TThrow e ->
		spr ctx "throw(";
		gen_value ctx e;
		spr ctx ")";
	| TVars [] ->
		()
	| TVars vl ->
		commentcode ctx "TVars vl";
		spr ctx "local ";
		concat ctx "; local " (fun (n,_,e) ->
			spr ctx (ident n);
			match e with
			| None -> ()
			| Some e ->
				spr ctx " = ";
				gen_value ctx e
		) vl;
(*		concat ctx ", " (fun (n,_,e) -> spr ctx (ident n); ) vl;
		List.iter (fun (n,_,e) ->
			match e with
			| None -> ()
			| Some e ->
				(match e.eexpr with
				| TIf(cond,etrue,efalse) ->
					newline ctx;
					gen_assign_if ctx (ident n) OpAssign cond etrue efalse
				| _ ->
					newline ctx;
					spr ctx (ident n);
					spr ctx " = ";
					gen_value ctx e
				);
		) vl*)
	| TNew (c,_,el) ->
		print ctx "%s:new (" (s_path ctx c.cl_path c.cl_extern e.epos);
		concat ctx "," (gen_value ctx) el;
		spr ctx ")"
	| TIf (cond,e,eelse) ->
		spr ctx "if";
		gen_value ctx (parent cond);
		spr ctx " then";
		let bend = open_block ctx in
		carriagereturn ctx;
		gen_expr ctx e;
			(*  Franco  *)
		(match eelse with
		| None -> ()
		| Some e when e.eexpr = TConst(TNull) -> ()
		| Some e ->
			newline ctx;
			spr ctx "else ";
			gen_expr ctx e);
		bend();
		newline ctx;
		spr ctx "end";
	| TUnop (op,Ast.Prefix,e) ->
		spr ctx (ms_unop op ctx e false);
	| TUnop (op,Ast.Postfix,e) ->
		spr ctx (ms_unop op ctx e true);
	| TWhile (cond,e,Ast.NormalWhile) ->
		let handle_break = handle_break ctx e in
		spr ctx "while";
		gen_value ctx (parent cond);
		spr ctx " do ";
		gen_block_body ctx e None;
		handle_break();
	| TWhile (cond,e,Ast.DoWhile) ->
		let handle_break = handle_break ctx e in
		spr ctx "repeat ";
		gen_expr ctx e;
		spr ctx " until(not ";
		gen_value ctx (parent cond);
		spr ctx ") -- DOWHILE";
		handle_break();
	| TObjectDecl fields ->
		commentcode ctx "TObjectDecl";
		spr ctx " lua.Boot.__makeObject({ ";
		concat ctx ", " (fun (f,e) -> print ctx "%s = " f; gen_value ctx e) fields;
		spr ctx " }, self)";
	| TFor (v,_,it,e) ->
		let handle_break = handle_break ctx e in
		let id = ctx.id_counter in
		ctx.id_counter <- ctx.id_counter + 1;
		print ctx "local ___it%d = " id;
		gen_value ctx it;
		newline ctx;
		print ctx "while( ___it%d:hasNext() ) do local %s = ___it%d:next();" id (ident v) id;
(* 		newline ctx; *)
(* 		gen_expr ctx e; *)
		gen_block_body ctx e None;
(* 		newline ctx; *)
(* 		spr ctx "end"; *)
		handle_break();
	| TTry (e,catchs) ->
		(* For some reason, try's following multiple failed if/then/end
			blocks just throw for now apparent reason. The noop() function
			prevents this
		*)
		spr ctx "noop() try ";
		gen_expr ctx (block e);
		newline ctx;
		let id = ctx.id_counter in
		ctx.id_counter <- ctx.id_counter + 1;
		print ctx "catch e%d do" id;
		let bend = open_block ctx in
		carriagereturn ctx;
		print ctx "if( e%d == nil or type(e%d) == \"string\") then e%d = Haxe.luaError(e%d) end" id id id id;
		newline ctx;
		let last = ref false in
		let openif = ref false in
		List.iter (fun (v,t,e) ->
			if !last then () else
			let t = (match follow t with
			| TEnum (e,_) -> Some (TEnumDecl e)
			| TInst (c,_) -> Some (TClassDecl c)
			| TFun _
			| TLazy _
			| TType _
			| TAnon _ ->
				assert false
			| TMono _
			| TDynamic _ ->
				None
			) in
			match t with
			| None ->
				last := true;
				spr ctx " do";
				let bend = open_block ctx in
				carriagereturn ctx;
				print ctx "local %s = e%d.error" v id;
				newline ctx;
				gen_expr ctx e;
				bend();
			| Some t ->
				openif := true;
				print ctx "if( lua.Boot.__instanceof(e%d.error," id;
				gen_value ctx (mk (TTypeExpr t) (mk_mono()) e.epos);
				spr ctx ") ) then do--621";
				let bend = open_block ctx in
				carriagereturn ctx;
				print ctx "local %s = e%d.error" v id;
				newline ctx;
				gen_expr ctx e;
				carriagereturn ctx;
				bend();
				commentcode ctx "629";
				spr ctx "end--630";
				newline ctx;
				spr ctx "else";
		) catchs;
		carriagereturn ctx;
		if not !last then print ctx "throw(e%d);" id;
		if !openif then print ctx "end";
		carriagereturn ctx;
		commentcode ctx "Try End Block";
		spr ctx "end";
		bend();
		newline ctx;
		commentcode ctx "End Catch";
		spr ctx "end";
	| TMatch (e,(estruct,_),cases,def) ->
		spr ctx "local ___e = ";
		gen_value ctx e;
		newline ctx;
		spr ctx "local switch = ___e[2]";
		newline ctx;
		let first = ref true in
		List.iter (fun (cl,params,e) ->
			List.iter (fun c ->
				if not !first then print ctx "else";
				print ctx "if switch == %d then" c;
				carriagereturn ctx;
				first := false;
			) cl;
			(match params with
			| None | Some [] -> ()
			| Some l ->
				let n = ref 2 in
				let l = List.fold_left (fun acc (v,_) -> incr n; match v with None -> acc | Some v -> (v,!n) :: acc) [] l in
				match l with
				| [] -> ()
				| l ->
					concat ctx "; " (fun (v,n) ->
						print ctx "local %s = ___e[%d]" v n;
					) l;
					newline ctx);
			gen_expr ctx (block e);
			newline ctx
		) cases;
		(match def with
		| None -> ()
		| Some e ->
			spr ctx "else ";
			gen_expr ctx (block e);
			newline ctx;
		);
		spr ctx "end"
	| TSwitch (e,cases,def) ->
		(* Generate a temp local var *)
		spr ctx "local switch = ";
		gen_value ctx (parent e);
		newline ctx;

		(* TSwitch of texpr * (texpr list * texpr) list * texpr option *)
		(* pop and create first case *)
		let b = (List.hd cases) in
		List.iter (fun e ->
			spr ctx "if (switch ==";
			gen_value ctx e;
			spr ctx ") then ";
		) (fst b);
		gen_expr ctx (block (snd b));
		newline ctx;

		List.iter (fun (tail,e2) ->
			List.iter (fun e ->
				spr ctx "elseif (switch == ";
				gen_value ctx e;
				spr ctx ") then ";
			) tail;
			gen_expr ctx (block e2);
			newline ctx;
		) (List.tl cases);
		(match def with
		| None -> ()
		| Some e ->
			spr ctx "else ";
			gen_expr ctx (block e);
			newline ctx;
		);
		spr ctx "end -- end of switch";
		newline ctx

and ms_unop op ctx e post =
	match op with
	| Increment ->
		let b = temp_ctx_buf ctx in
		gen_value ctx e;
		let bc = Buffer.contents ctx.buf in
		let s = unop_string post (true) bc in
		b();
		s;
	| Decrement ->
		let b = temp_ctx_buf ctx in
		gen_value ctx e;
		let bc = Buffer.contents ctx.buf in
		let s = unop_string post (false) bc in
		b();
		s;
	| Not ->
		let b = temp_ctx_buf ctx in
		spr ctx " not ";
		gen_value ctx e;
		let bc = Buffer.contents ctx.buf in
		b();
		bc;
	| Neg ->
		let b = temp_ctx_buf ctx in
		spr ctx "-";
		gen_value ctx e;
		let bc = Buffer.contents ctx.buf in
		b();
		bc;
	| NegBits ->
		let b = temp_ctx_buf ctx in
		spr ctx "~";
		gen_value ctx e;
		let bc = Buffer.contents ctx.buf in
		b();
		bc;

and gen_function_header ctx name f args p =
	let old = ctx.in_value in
	ctx.in_value <- false;
(*	ctx.local_types <- List.map snd params @ ctx.local_types;*)
	print ctx "function%s(" (match name with None -> "" | Some n -> " " ^ n);
	concat ctx "," (fun (arg,o,t) ->
		print ctx "%s" (ident arg);
	) args;
	print ctx ")";
	(fun () ->
		ctx.in_value <- old;
	)

(*
	Generates a function body. No do will be added
	ctx -> tfunc -> Void
*)
and gen_function_body ctx f extra =
	let e = (fun_block ctx f) in
		gen_block_body ctx e extra

and gen_block_body ctx f extra =
	let e = (block f) in
	let bend = open_block ctx in
		carriagereturn ctx;
		(match e.eexpr with
		| TBlock el ->
			let first = ref true in
			List.iter (fun e ->
				if not !first then newline ctx else first := false;
				gen_expr ctx e ) el;
		| _ ->
			assert false;
		);
		(match extra with
		| None -> ()
		| Some e ->
			newline ctx;
			print ctx "%s" e
		);
	bend();
	newline ctx;
	spr ctx "end"


and gen_value ctx e =
	let assign e =
		mk (TBinop (Ast.OpAssign,
			mk (TLocal "r") t_dynamic e.epos,
			e
		)) e.etype e.epos
	in
	let value block =
		let old = ctx.in_value in
		ctx.in_value <- true;
		spr ctx "(function(this) ";
		let b = if block then begin
			let b = open_block ctx in
			carriagereturn ctx;
			spr ctx "local r";
			newline ctx;
			b
		end else
			(fun() -> ())
		in
		(fun() ->
			if block then begin
				newline ctx;
				spr ctx "return r";
				b();
				newline ctx;
				spr ctx "end)";
			end;
			ctx.in_value <- old;
			print ctx "(%s)" (this ctx)
		)
	in
	match e.eexpr with
	| TConst _
	| TLocal _
	| TEnumField _
	| TArray _
	| TBinop _
	| TField _
	| TTypeExpr _
	| TParenthesis _
	| TObjectDecl _
	| TArrayDecl _
	| TCall _
	| TNew _
	| TUnop _
	| TFunction _ ->
		gen_expr ctx e
	| TReturn _
	| TBreak
	| TContinue ->
		unsupported e.epos
	| TVars _
	| TFor _
	| TWhile _
	| TThrow _ ->
		(* value is discarded anyway *)
		let v = value true in
		gen_expr ctx e;
		v()
	| TBlock [e] ->
		gen_value ctx e
	| TBlock el ->
		let v = value true in
		let rec loop = function
			| [] ->
				spr ctx "return nil";
			| [e] ->
				gen_expr ctx (assign e);
			| e :: l ->
				gen_expr ctx e;
				newline ctx;
				loop l
		in
		loop el;
		v();
	| TIf (cond,e,eo) ->
		commentcode ctx "TIf (cond,e,eo)";
		spr ctx "lua.Boot.__ternary(";
		gen_value ctx cond;
		spr ctx ", function() return ";
		gen_value ctx e;
		spr ctx " end, function() return ";
		(match eo with
		| None -> spr ctx "nil"
		| Some e -> gen_value ctx e);
		spr ctx " end)"
	| TSwitch (cond,cases,def) ->
		let v = value true in
		gen_expr ctx (mk (TSwitch (cond,
			List.map (fun (e1,e2) -> (e1,assign e2)) cases,
			match def with None -> None | Some e -> Some (assign e)
		)) e.etype e.epos);
		v()
	| TMatch (cond,enum,cases,def) ->
		let v = value true in
		gen_expr ctx (mk (TMatch (cond,enum,
			List.map (fun (constr,params,e) -> (constr,params,assign e)) cases,
			match def with None -> None | Some e -> Some (assign e)
		)) e.etype e.epos);
		v()
	| TTry (b,catchs) ->
		print ctx "-- TTry";
		newline ctx;
		let v = value true in
		gen_expr ctx (mk (TTry (assign b,
			List.map (fun (v,t,e) -> v, t , assign e) catchs
		)) e.etype e.epos);
		v()




(*
	add a descriptor to the '__statics__' object for a class
	Required for Reflect type 'hasOwnProperty'
*)
let mark_static_field ctx c f is_var =
	match is_var with
	| true ->
		print ctx "__statics__['%s'] = \"object\"" f.cf_name;
		newline ctx
	| false ->
		print ctx "__statics__['%s'] = %s%s" f.cf_name (s_path1 c.cl_path) (staticfield f.cf_name);
		newline ctx

let generate_field ctx static f =
	carriagereturn ctx;
	ctx.in_static <- static;
	let p = ctx.curclass.cl_pos in
	match f.cf_expr with
	| Some { eexpr = TFunction fd } ->
		(match static with
		| true -> register_static ctx (s_ident f.cf_name) (s_ident f.cf_name);
		| false -> register_prototype ctx (s_ident f.cf_name) (s_ident f.cf_name)
		);
		let args = (match static with
			| true -> fd.tf_args
			| false -> ("self",true,mk_mono()) :: fd.tf_args) in
		let h =
			gen_function_header ctx (Some (s_ident f.cf_name)) fd args p in
			gen_function_body ctx fd None;
		h()
	| _ ->
		if ctx.curclass.cl_interface then
			match follow f.cf_type with
			| TFun (args,r) ->
				print ctx "function %s(" f.cf_name;
				concat ctx ", " (fun (arg,o,t) ->
					print ctx "%s" arg;
				) args;
				print ctx ") end";
			| _ -> ()
		else
		if (match f.cf_get with MethodAccess m -> true | _ -> match f.cf_set with MethodAccess m -> true | _ -> false) then begin
(*			let id = s_ident f.cf_name in
			(match f.cf_get with
			| NormalAccess ->
				print ctx "function get %s() { return $%s; }" id id;
				newline ctx
			| MethodAccess m ->
				print ctx "function get %s() { return %s(); }" id m;
				newline ctx
			| _ -> ());
			(match f.cf_set with
			| NormalAccess ->
				print ctx "function set %s( __v ) { $%s = __v; }" id id;
				newline ctx
			| MethodAccess m ->
				print ctx "function set %s( __v ) { %s(__v); }" id m;
				newline ctx
			| _ -> ());
			print ctx "protected $%s" (s_ident f.cf_name);*)
		end else begin
			(* class member variables *)
			(match static with
				| true ->
					register_static ctx (s_ident f.cf_name) "'object'";
				| false ->
					register_prototype ctx (s_ident f.cf_name) "'object'"
			);
			match f.cf_expr with
			| None -> ()
			| Some e ->
				print ctx "%s = " (s_ident f.cf_name);
				gen_value ctx e
		end


let generate_class ctx c =
	ctx.curclass <- c;
	ctx.curmethod <- ("new",true);

	let p = s_path1 c.cl_path in
	(match c.cl_super with
	| None -> ()
	| Some (csup,_) ->
		let psup = s_path ctx csup.cl_path csup.cl_extern c.cl_pos in
		print ctx "getmetatable(%s).__index = %s\n" p psup;
		print ctx "%s.__super__ = %s\n" p psup;
	);

	print ctx "%s.__class__ = %s\n" p p;
	print ctx "%s.__name__= Array:new({%s});\n" p (String.concat "," (List.map (fun s -> Printf.sprintf "\"%s\"" (Ast.s_escape s)) (fst c.cl_path @ [snd c.cl_path])));
	print ctx "%s.prototype = {}\n" p;
	print ctx "%s.__statics__ = {}\n\n" p;

	print ctx "-- %s constructor\n" p;
	print ctx "function %s:__construct__(o)\n" p;
	print ctx "\to = o or {}\n";
	print ctx "\tsetmetatable(o, self)\n";
	print ctx "\tself.__index = self\n";

(* 	print ctx "\t%s.__name__ = Array:new({%s})\n" p (String.concat "," (List.map (fun s -> Printf.sprintf "\"%s\"" (Ast.s_escape s)) (fst c.cl_path @ [snd c.cl_path]))); *)
	print ctx "\treturn o\n";
	print ctx "end\n\n";

	print ctx "function %s" p;
	(match c.cl_constructor with
	| Some { cf_expr = Some e } ->
		(match Transform.block_vars e with
		| { eexpr = TFunction f } ->
			let args  = List.map arg_name f.tf_args in
			let a, args = (match args with [] -> "p" , ["p"] | x :: _ -> x, args) in
			print ctx ":new (%s)" (String.concat "," (List.map ident args)) ;
			carriagereturn ctx;
			print ctx "%s\tlocal ___new =%s:__construct__()" ctx.tabs p;
			ctx.in_constructor <- true;
			gen_function_body ctx f (Some (Printf.sprintf "return ___new"));
			ctx.in_constructor <- false;
			carriagereturn ctx;
		| _ -> assert false)
	| _ ->
		print ctx ":new ()\n";
		print ctx "\tlocal ___new =%s:__construct__()\n" p;
		print ctx "\treturn ___new\nend\n");
	carriagereturn ctx;

(*	List.iter (gen_class_static_field ctx c) c.cl_ordered_statics;
	PMap.iter (fun _ f -> if f.cf_get <> ResolveAccess then gen_class_field ctx c f) c.cl_fields;*)

	print ctx "\n--GENERATE_FIELD STATICS--\n";
	List.iter (generate_field ctx true) c.cl_ordered_statics;
	print ctx "\n\n--GENERATE_FIELD MEMBERS--\n";
	List.iter (fun f ->
		if f.cf_get <> ResolveAccess then generate_field ctx false f;
	) c.cl_ordered_fields;
(* 	List.iter (generate_field ctx false) c.cl_ordered_fields; *)
	match c.cl_implements with
	| [] -> ()
	| l ->
		carriagereturn ctx;
		print ctx "%s.__interfaces__ = {%s}" p (String.concat "," (List.map (fun (i,_) -> s_path ctx i.cl_path i.cl_extern c.cl_pos) l))


let generate_enum ctx e =
(* 	let p = s_path1 e.e_path in *)
	let p = s_path ctx e.e_path e.e_extern e.e_pos in
	let ename = List.map (fun s -> Printf.sprintf "\"%s\"" (Ast.s_escape s)) (fst e.e_path @ [snd e.e_path]) in
	print ctx "__ename__ = Array:new({%s})" (String.concat "," ename);
	newline ctx;
	print ctx "__constructs__ = Array:new({%s})" (String.concat "," (List.map (fun s -> Printf.sprintf "\"%s\"" s) e.e_names));
	newline ctx;
	PMap.iter (fun _ f ->
		print ctx "%s = " f.ef_name;
		(match f.ef_type with
		| TFun (args,_) ->
			let sargs = String.concat "," (List.map arg_name args) in
			print ctx " function(%s) ___x = {\"%s\",%d,%s}; ___x.__enum__ = %s; ___x.toString = lua.Boot.__string_rec; return ___x; end" sargs f.ef_name f.ef_index sargs p;
		| _ ->
			print ctx "{\"%s\",%d}" f.ef_name f.ef_index;
			newline ctx;
			print ctx "%s.toString = lua.Boot.__string_rec" f.ef_name;
			newline ctx;
			print ctx "%s.__enum__ = %s" f.ef_name p;
		);
		newline ctx
	) e.e_constrs

let generate_static ctx (c,f,e) =
	print ctx "%s%s = " (s_path ctx c.cl_path c.cl_extern e.epos) (staticfield f);
	gen_value ctx e;
	newline ctx

(*
let generate_type ctx = function
	| TClassDecl c ->
		(match c.cl_init with
		| None -> ()
		| Some e -> ctx.inits <- Transform.block_vars e :: ctx.inits);
		if not c.cl_extern then generate_class ctx c
	| TEnumDecl e when e.e_extern ->
		()
	| TEnumDecl e -> generate_enum ctx e
	| TTypeDecl _ -> ()
*)

let generate_main ctx c =
	(match c.cl_ordered_statics with
	| [{ cf_expr = Some e }] ->
		gen_value ctx e;
	| _ -> assert false);
	register_required_path ctx (["lua"], "Boot");
	register_required_path ctx ([], "Haxe");
	newline ctx

(*let generate_base_enum ctx =
	let pack = open_block ctx in
	spr ctx "\tpublic class enum {";
	let cl = open_block ctx in
	newline ctx;
	spr ctx "public var tag : String";
	newline ctx;
	spr ctx "public var index : int";
	newline ctx;
	spr ctx "public var params : Array";
	cl();
	newline ctx;
	print ctx "}";
	pack();
	newline ctx;
	print ctx "}";
	newline ctx*)

let generate dir types =
	(*let ctx = init dir ([],"enum") in
	generate_base_enum ctx;
	close ctx;*)
	List.iter (fun t ->
		(match t with
		| TClassDecl c ->
			let c = (match c.cl_path with
				| ["lua"],"LuaArray__"    -> { c with cl_path = [],"Array" }
				| ["lua"],"LuaDate__"   -> { c with cl_path = [],"Date" }
				| ["lua"],"LuaMath__"   -> { c with cl_path = [],"Math" }
				| ["lua"],"LuaString__"   -> { c with cl_path = [],"String" }
				| ["lua"],"LuaXml__"    -> { c with cl_path = [],"Xml" }
				| _ -> c
			) in
			if c.cl_extern then
				()
			else (match c.cl_path with
				| [], "@Main" ->
					let ctx = init dir ([], "__main__") in
					generate_main ctx c;
					close ctx;
				| _ ->
					let ctx = init dir c.cl_path in
					generate_class ctx c;
					(match c.cl_init with
					| None -> ()
					| Some e -> gen_expr ctx e);
						close ctx
				)
		| TEnumDecl e ->
			if e.e_extern then
				()
			else
				let ctx = init dir e.e_path in
					generate_enum ctx e;
				close ctx
		| TTypeDecl t ->
			()
		);
(* 		newline ctx; *)
	) types


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
	mutable buf : Buffer.t;
	packages : (string list,unit) Hashtbl.t;
	mutable curclass : tclass;
	mutable statics : (tclass * string * texpr) list;
	mutable inits : texpr list;
	mutable tabs : string;
	mutable in_value : bool;
	mutable in_constructor : bool;
	mutable in_function : bool;
	mutable handle_break : bool;
	mutable id_counter : int;
	debug : bool;
	mutable curmethod : (string * bool);
	commentcode : bool;
}

let s_path = function
	| ([],"@Main") -> "Main"
	| p -> Ast.s_type_path p

let kwds =
	let h = Hashtbl.create 0 in
	List.iter (fun s -> Hashtbl.add h s ()) [
		"and"; "break"; "do"; "else"; "elseif";
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
	| "is" -> "_is"
	| "as" -> "_as"
	| "int" -> "_int"
	| "const" -> "_const"
	| "getTimer" -> "_getTimer"
	| "typeof" -> "_typeof"
	| "parseInt" -> "_parseInt"
	| "parseFloat" -> "_parseFloat"
	| _ -> n

let spr ctx s = Buffer.add_string ctx.buf s
let print ctx = Printf.kprintf (fun s -> Buffer.add_string ctx.buf s)

let unsupported = Typer.error "This expression cannot be compiled to Lua"

let newline ctx =
	match Buffer.nth ctx.buf (Buffer.length ctx.buf - 1) with
	| ':' -> print ctx "\n%s" ctx.tabs
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
	| OpXor -> "|^"
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

let handle_break ctx e =
	let old_handle = ctx.handle_break in
	try
		iter_switch_break false e;
		ctx.handle_break <- false;
		(fun() -> ctx.handle_break <- old_handle)
	with
		Exit ->
			spr ctx "try {";
			let b = open_block ctx in
			newline ctx;
			ctx.handle_break <- true;
			(fun() ->
				b();
				ctx.handle_break <- old_handle;
				newline ctx;
				spr ctx "} catch( e ) { if( e != \"__break__\" ) throw e; }";
			)

let this ctx =
	if ctx.in_constructor then "___new" else
		if ctx.in_value then "this" else "self"

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
		if(c == ctx.curclass) then false
		else true
	| _ ->
		false

let rec gen_call ctx e el =
	match e.eexpr , el with
	| TConst TSuper , params ->
		(match ctx.curclass.cl_super with
		| None -> assert false
		| Some (c,_) ->
			commentcode ctx "TConst TSuper";
			print ctx "%s.new(" (s_path c.cl_path);
			concat ctx "," (gen_value ctx) params;
			spr ctx ")";
		);
	| TField ({ eexpr = TConst TSuper },name) , params ->
		(match ctx.curclass.cl_super with
		| None -> assert false
		| Some (c,_) ->
			commentcode ctx "TField super";
(* 			member method super call *)
			print ctx "%s%s(" (s_path c.cl_path) (staticfield name);
			concat ctx "," (gen_value ctx) params;
			spr ctx ")"
		);
	| TField (e,s) , el ->
(* 		| TField of texpr * string *)
		commentcode ctx "gen_call TField";
		gen_value ctx e;
		(* spr ctx (staticfield s); *)
		let is_func = is_method ctx e.etype s in
		gen_field_access ctx (not is_func) e.etype s;
		spr ctx "(";
		concat ctx "," (gen_value ctx) el;
		spr ctx ")"
	| TCall (x,_) , el when x.eexpr <> TLocal "__lua__" ->
		spr ctx "--[[TCALL--]]";
		spr ctx "(";
		gen_value ctx e;
		spr ctx ")";
		spr ctx "(";
		concat ctx "," (gen_value ctx) el;
		spr ctx ")";
	| TLocal "__new__" , { eexpr = TConst (TString cl) } :: params ->
		print ctx "new %s(" cl;
		concat ctx "," (gen_value ctx) params;
		spr ctx ")";
	| TLocal "__new__" , e :: params ->
		spr ctx "new ";
		gen_value ctx e;
		spr ctx "(";
		concat ctx "," (gen_value ctx) params;
		spr ctx ")";
	| TLocal "__lua__", [{ eexpr = TConst (TString code) }] ->
		spr ctx code
	| _ ->
		gen_value ctx e;
		spr ctx "(";
		concat ctx "," (gen_value ctx) el;
		spr ctx ")"

and gen_value_op ctx e =
	match e.eexpr with
	| TBinop (op,_,_) when op = Ast.OpAnd || op = Ast.OpOr || op = Ast.OpXor ->
		spr ctx "(";
		gen_value ctx e;
		spr ctx ")";
	| _ ->
		gen_value ctx e

(*and is_method ctx t s =
	match follow t with
	| TInst(c,_) ->
		if(c == ctx.curclass) then false;
		else true;
	| _ ->
		false;*)

(* context Type.t fieldname *)
and gen_field_access ctx isvar t s =
	let field c member =
		match fst c.cl_path, snd c.cl_path with
		| [], "Math"
		-> 	 print ctx ".%s" (s_ident s)
		| [], "Date"
		-> 	(match s with
			| "now"
			| "fromTime"
			| "fromString"
			| "toString"
			| _
			-> print ctx "unhandled warning"
			);
		| [], "String"
		->	(match s with
			| "length" -> print ctx ":len()"
			| _ -> print ctx ":haxe_%s" s
			);
		| _ ->
			print ctx "%s%s" (fieldaccess member) (s_ident s)

	in
	match follow t with
	| TInst (c,_) ->
(* 		spr ctx "--tinst--"; *)
		if c == ctx.curclass then field c false
		else if isvar then field c false else field c true;
	| TAnon a ->
		(match !(a.a_status) with
		| Statics c ->
(* 			spr ctx "--tanon static--"; *)
			field c false
		| _ ->
(* 			spr ctx "--tanon unmatched--"; *)
			print ctx "%s%s" (if isvar then "." else ":")(s_ident s))
	| _ ->
		print ctx ".%s" (s_ident s)

(*	in
	match follow t with
	| TInst (c,_) ->
		if c == ctx.curclass then field c
		else print ctx ":%s" (s_ident s);
	| TAnon a ->
		(match !(a.a_status) with
		| Statics c -> field c
		| _ -> print ctx ":%s" (s_ident s))
	| _ ->
		print ctx ":%s" (s_ident s)*)

and gen_expr ctx e =
	match e.eexpr with
	| TConst c -> gen_constant ctx e.epos c
	| TLocal s -> spr ctx (ident s)
	| TEnumField (e,s) ->
		print ctx "%s%s" (s_path e.e_path) (staticfield s)
	| TArray (e1,e2) ->
		gen_value ctx e1;
		spr ctx "[";
		gen_value ctx e2;
		spr ctx "]";
	| TBinop (op,{ eexpr = TField (e1,s) },e2) ->
		(match op with
		| OpAssignOp o ->
			commentcode ctx "OpAssignOpa";
			gen_value_op ctx e1;
			(* spr ctx (staticfield s); *)
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
			(* spr ctx (staticfield s); *)
			gen_field_access ctx true e1.etype s;
			print ctx " %s " (s_binop op);
			commentcode ctx "TBinop (op,{ eexpr = TField (e1,s) },e2) b";
			gen_value_op ctx e2;
		)
	| TBinop (op,e1,e2) ->
		(match op with
		| OpAssignOp o ->
			commentcode ctx "OpAssignOp2";
			gen_value_op ctx e1;
			print ctx " = ";
			gen_value_op ctx e1;
			print ctx " %s " (s_binop op);
			print ctx "(";
			gen_value_op ctx e2;
			print ctx ")";
		| _ ->
			commentcode ctx "OpAssignOp2 case 2";
			gen_value_op ctx e1;
			print ctx " %s " (s_binop op);
			gen_value_op ctx e2;
		)
	| TField (x,s) ->
		(match follow e.etype with
		| TFun _ ->
			spr ctx "$closure(";
			gen_value ctx x;
			spr ctx ",";
			gen_constant ctx e.epos (TString s);
			spr ctx ")";
		| _ ->
			commentcode ctx "TField (x,s)";
			gen_value ctx x;
			gen_field_access ctx true x.etype s;
			)
	| TTypeExpr t ->
		spr ctx (s_path (t_path t))
	| TParenthesis e ->
		spr ctx "(";
		gen_value ctx e;
		spr ctx ")";
	| TReturn eo ->
		if ctx.in_value then unsupported e.epos;
		(match eo with
		| None ->
			spr ctx "return"
		| Some e ->
			spr ctx "return ";
			gen_value ctx e);
	| TBreak ->
		if ctx.in_value then unsupported e.epos;
		if ctx.handle_break then spr ctx "throw \"__break__\"" else spr ctx "break"
	| TContinue ->
		if ctx.in_value then unsupported e.epos;
		spr ctx "continue"
	| TBlock [] ->
		spr ctx "-- gen_expr TBlock [] nil"
	| TBlock el ->
		print ctx "do";
		let bend = open_block ctx in
		List.iter (fun e -> newline ctx; gen_expr ctx e) el;
		bend();
		newline ctx;
		print ctx "end";
	| TFunction f ->
(*
		if ctx.in_function then
			print ctx "function";
*)
		let old = ctx.in_value in
		let old_meth = ctx.curmethod in
		let old_infunc = ctx.in_function in
		ctx.in_value <- false;
		if snd ctx.curmethod then begin
			ctx.curmethod <- (fst ctx.curmethod ^ "@" ^ string_of_int (Lexer.get_error_line e.epos), true);
			print ctx "function ";
			ctx.in_function <- true;
		end
		else
			ctx.curmethod <- (fst ctx.curmethod, true);
		print ctx "(%s) " (String.concat "," (List.map ident (List.map arg_name f.tf_args)));
 		carriagereturn ctx;
		gen_expr ctx (fun_block ctx f);
		if ctx.in_function then begin
			newline ctx;
			print ctx "end -- end local function decl";
			carriagereturn ctx;
		end;
		ctx.in_function <- old_infunc;
		ctx.curmethod <- old_meth;
		ctx.in_value <- old;
	| TCall (e,el) ->
		gen_call ctx e el
	| TArrayDecl el ->
		spr ctx "[";
		concat ctx "," (gen_value ctx) el;
		spr ctx "]"
	| TThrow e ->
		spr ctx "throw(";
		gen_value ctx e;
		spr ctx ")";
	| TVars [] ->
		()
	| TVars vl ->
		spr ctx "local ";
		concat ctx "; local " (fun (n,_,e) ->
			spr ctx (ident n);
			match e with
			| None -> ()
			| Some e ->
				spr ctx " = ";
				gen_value ctx e
		) vl;
	| TNew (c,_,el) ->
		print ctx "%s:new (" (s_path c.cl_path);
		concat ctx "," (gen_value ctx) el;
		spr ctx ")"
	| TIf (cond,e,eelse) ->
		spr ctx "if";
		gen_value ctx (parent cond);
		spr ctx " then ";
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
		gen_expr ctx e;
		spr ctx " end ";
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
		spr ctx " { ";
		concat ctx ", " (fun (f,e) -> print ctx "%s = " f; gen_value ctx e) fields;
		spr ctx " }";
	| TFor (v,_,it,e) ->
		let handle_break = handle_break ctx e in
		let id = ctx.id_counter in
		ctx.id_counter <- ctx.id_counter + 1;
		print ctx "TFor { var ___it%d = " id;
		gen_value ctx it;
		newline ctx;
		print ctx "while( ___it%d.hasNext() ) { var %s = ___it%d.next()" id (ident v) id;
		newline ctx;
		gen_expr ctx e;
		newline ctx;
		spr ctx "}}";
		handle_break();
	| TTry (e,catchs) ->
		spr ctx "try ";
		gen_expr ctx (block e);
		newline ctx;
		let id = ctx.id_counter in
		ctx.id_counter <- ctx.id_counter + 1;
		print ctx "catch e%d do " id;
		let bend = open_block ctx in
		carriagereturn ctx;
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
				spr ctx " do --494";
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
				spr ctx ") ) then do";
				let bend = open_block ctx in
				carriagereturn ctx;
				print ctx "local %s = e%d.error" v id;
				newline ctx;
				gen_expr ctx e;
				bend();
				newline ctx;
				commentcode ctx "627";
				spr ctx "end";
				newline ctx;
				spr ctx "else";
		) catchs;
		if not !last then print ctx "throw(e%d)" id;
		newline ctx;
		if !openif then print ctx "end -- End If";
		newline ctx;
		commentcode ctx "Try End Block";
		spr ctx "end";
		bend();
		newline ctx;
		commentcode ctx "End Catch";
		spr ctx "end";
		newline ctx;
	| TMatch (e,(estruct,_),cases,def) ->
		spr ctx "local ___e = ";
		gen_value ctx e;
		newline ctx;
		spr ctx "switch( ___ee[1] ) {";
		newline ctx;
		List.iter (fun (cl,params,e) ->
			List.iter (fun c ->
				print ctx "case %d:" c;
				newline ctx;
			) cl;
			(match params with
			| None | Some [] -> ()
			| Some l ->
				let n = ref 1 in
				let l = List.fold_left (fun acc (v,_) -> incr n; match v with None -> acc | Some v -> (v,!n) :: acc) [] l in
				match l with
				| [] -> ()
				| l ->
					spr ctx "local ";
					concat ctx ", " (fun (v,n) ->
						print ctx "%s = ___e[%d]" v n;
					) l;
					newline ctx);
			gen_expr ctx (block e);
			print ctx "break";
			newline ctx
		) cases;
		(match def with
		| None -> ()
		| Some e ->
			spr ctx "default:";
			gen_expr ctx (block e);
			print ctx "break";
			newline ctx;
		);
		spr ctx "}"
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
		spr ctx "((";
		gen_value ctx cond;
		spr ctx ") and (";
		gen_value ctx e;
		spr ctx ") or (";
		(match eo with
		| None -> spr ctx "gen_value TIf nil"
		| Some e -> gen_value ctx e);
		spr ctx "))"
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



let generate_package_create ctx (p,_) =
	let rec loop acc = function
		| [] -> ()
		| p :: l when Hashtbl.mem ctx.packages (p :: acc) -> loop (p :: acc) l
		| p :: l ->
			Hashtbl.add ctx.packages (p :: acc) ();
			(match acc with
			| [] ->
				print ctx "-- package create1\n";
				print ctx "%s = {}" p;
			| _ ->
				print ctx "-- package create2\n";
				print ctx "%s%s = {}" (String.concat "." (List.rev acc)) (staticfield p));
			newline ctx;
			loop (p :: acc) l
	in
	loop [] p

(*
	Generates a function body. No do or end will be added
	and it is assumed that the indentation is already setup
	ctx -> tfunc -> Void
*)
let gen_function_body ctx f =
	let e = (fun_block ctx f) in
	match e.eexpr with
	| TBlock el ->
(* 		spr ctx "-- begin function body"; *)
		List.iter (fun e -> newline ctx; gen_expr ctx e) el;
(* 		spr ctx "--end body"; *)
		newline ctx
	| _ ->
		assert false

(*
let gen_field_body ctx e =
	match e.eexpr with
	| TBlock el ->
		(* let bend = open_block ctx in *)
		List.iter (fun e -> newline ctx; gen_expr ctx e) el;
		(* bend(); *)
		newline ctx
	| TFunction f ->
		print ctx "-- HERE BE FUNCTION";
		gen_value ctx e;
		print ctx "-- AYE, I BE DONE";
		newline ctx
	| _ ->
		assert false
*)

let gen_class_static_field ctx c f =
	match f.cf_expr with
	| None ->
		commentcode ctx "gen_class_static_field1";
(*		if ctx.commentcode then begin
			print ctx "-- gen_class_static_field1";
			carriagereturn ctx;
		end;*)
		print ctx "%s%s = nil" (s_path c.cl_path) (staticfield f.cf_name);
		newline ctx
	| Some e ->
		let e = Transform.block_vars e in
		match e.eexpr with
		| TFunction _ ->
			ctx.curmethod <- (f.cf_name,false);
			commentcode ctx "gen_class_static_field2";
			print ctx "function %s%s " (s_path c.cl_path) (staticfield f.cf_name);
			(* gen_value ctx e; *)
			let bend = open_block ctx in
				(*gen_function_body ctx e; *)
				gen_value ctx e;
			bend();
			carriagereturn ctx;
			print ctx "end";
			newline ctx;
		| _ ->
			ctx.statics <- (c,f.cf_name,e) :: ctx.statics




(*
let generate_field ctx static f =
	newline ctx;
	ctx.in_static <- static;
	ctx.locals <- PMap.empty;
	ctx.inv_locals <- PMap.empty;
	let p = ctx.curclass.cl_pos in
	match f.cf_expr with
	| Some { eexpr = TFunction fd } when f.cf_set = F9MethodAccess ->
		print ctx "%s " rights;
		let rec loop c =
			match c.cl_super with
			| None -> ()
			| Some (c,_) ->
				if PMap.mem f.cf_name c.cl_fields then
					spr ctx "override "
				else
					loop c
		in
		if not static then loop ctx.curclass;
		let h = gen_function_header ctx (Some (s_ident f.cf_name)) fd f.cf_params p in
		gen_expr ctx (block fd.tf_expr);
		h()
	| _ ->
		if ctx.curclass.cl_path = (["flash"],"Boot") && f.cf_name = "init" then
			generate_boot_init ctx
		else if ctx.curclass.cl_interface then
			match follow f.cf_type with
			| TFun (args,r) ->
				print ctx "function %s(" f.cf_name;
				concat ctx "," (fun (arg,o,t) ->
					print ctx "%s : %s" arg (type_str ctx t p);
					if o then spr ctx " = null";
				) args;
				print ctx ") : %s " (type_str ctx r p);
			| _ -> ()
		else
		if (match f.cf_get with MethodAccess m -> true | _ -> match f.cf_set with MethodAccess m -> true | _ -> false) then begin
			let t = type_str ctx f.cf_type p in
			let id = s_ident f.cf_name in
			(match f.cf_get with
			| NormalAccess ->
				print ctx "%s function get %s() : %s { return $%s; }" rights id t id;
				newline ctx
			| MethodAccess m ->
				print ctx "%s function get %s() : %s { return %s(); }" rights id t m;
				newline ctx
			| _ -> ());
			(match f.cf_set with
			| NormalAccess ->
				print ctx "%s function set %s( __v : %s ) : void { $%s = __v; }" rights id t id;
				newline ctx
			| MethodAccess m ->
				print ctx "%s function set %s( __v : %s ) : void { %s(__v); }" rights id t m;
				newline ctx
			| _ -> ());
			print ctx "protected var $%s : %s" (s_ident f.cf_name) (type_str ctx f.cf_type p);
		end else begin
			print ctx "%s var %s : %s" rights (s_ident f.cf_name) (type_str ctx f.cf_type p);
			match f.cf_expr with
			| None -> ()
			| Some e ->
				print ctx " = ";
				gen_value ctx e
		end
*)

(*
	context->tclass->tclass_field->Void
*)
let gen_class_field ctx c f =
	if ctx.commentcode then begin
		print ctx "-- gen_class_field %s%s " (s_path c.cl_path) (member f.cf_name);
		carriagereturn ctx;
	end;
	(match f.cf_expr with
	| None ->
		print ctx "%s%s = nil" (s_path c.cl_path) (staticfield f.cf_name);
	| Some e ->
		print ctx "function %s%s " (s_path c.cl_path) (member f.cf_name);
		ctx.curmethod <- (f.cf_name,false);
		gen_value ctx (Transform.block_vars e);
		(* gen_field_body ctx (Transform.block_vars e); *)
		newline ctx;
		print ctx "end";
	);
	newline ctx;
	carriagereturn ctx

let generate_class ctx c =
	ctx.curclass <- c;
	ctx.curmethod <- ("new",true);

	let p = s_path c.cl_path in
	generate_package_create ctx c.cl_path;

	let ppath = (match List.rev (ExtString.String.nsplit p ".") with
		[] -> ""
		| x :: l
		-> (match List.rev l with
			[] -> ""
			| x :: l -> String.concat "." (x :: l) ^ "."
			);
		) in
	print ctx "\n%s = {_NAME='%s', _M=%s, _PACKAGE='%s'}\n" p p p ppath;
	print ctx "package.loaded['%s'] = %s\n" p p;
	print ctx "-- %s constructor\n" p;
	print ctx "function %s:__construct__(o)\n" p;
	print ctx "\to = o or {}\n";
	print ctx "\tsetmetatable(o, self)\n";
	print ctx "\tself.__index = self\n";
	print ctx "\tself.__class__ = %s\n" p;
	print ctx "\tself.__name__ = \"%s" p;
(*
 (String.concat "," (List.map (fun s -> Printf.sprintf "\"%s\"" (Ast.s_escape s)) (fst c.cl_path @ [snd c.cl_path])));
*)
	print ctx "\"\n";
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
			let bend = open_block ctx in
				carriagereturn ctx;
				print ctx "local ___new =%s:__construct__()" p;
				ctx.in_constructor <- true;
				gen_function_body ctx f;
				ctx.in_constructor <- false;
				print ctx "return ___new";
			bend();
			newline ctx;
			print ctx "end";
			carriagereturn ctx;
		| _ -> assert false)
	| _ ->
		print ctx ":new ()\n";
		print ctx "\tlocal new =%s:new()\n" p;
		print ctx "\treturn new\nend\n");
	carriagereturn ctx;
	(match c.cl_super with
	| None -> ()
	| Some (csup,_) ->
		let psup = s_path csup.cl_path in
		print ctx "%s.__super__ = %s" p psup;
		newline ctx;
	);
	List.iter (gen_class_static_field ctx c) c.cl_ordered_statics;
	PMap.iter (fun _ f -> if f.cf_get <> ResolveAccess then gen_class_field ctx c f) c.cl_fields;
	match c.cl_implements with
	| [] -> ()
	| l ->
		print ctx "%s.__interfaces__ = {%s}" p (String.concat "," (List.map (fun (i,_) -> s_path i.cl_path) l));
		newline ctx

let generate_enum ctx e =
	let p = s_path e.e_path in
	generate_package_create ctx e.e_path;
	let ename = List.map (fun s -> Printf.sprintf "\"%s\"" (Ast.s_escape s)) (fst e.e_path @ [snd e.e_path]) in
	print ctx "%s = { __ename__ : [%s], __constructs__ : [%s] }" p (String.concat "," ename) (String.concat "," (List.map (fun s -> Printf.sprintf "\"%s\"" s) e.e_names));
	newline ctx;
	PMap.iter (fun _ f ->
		print ctx "%s%s = " p (staticfield f.ef_name);
		(match f.ef_type with
		| TFun (args,_) ->
			let sargs = String.concat "," (List.map arg_name args) in
			print ctx "(%s) { var ___x = [\"%s\",%d,%s]; ___x.__enum__ = %s; ___x.toString = $estr; return ___x; }" sargs f.ef_name f.ef_index sargs p;
		| _ ->
			print ctx "[\"%s\",%d]" f.ef_name f.ef_index;
			newline ctx;
			print ctx "%s%s.toString = $estr" p (staticfield f.ef_name);
			newline ctx;
			print ctx "%s%s.__enum__ = %s" p (staticfield f.ef_name) p;
		);
		newline ctx
	) e.e_constrs

let generate_static ctx (c,f,e) =
	print ctx "%s%s = " (s_path c.cl_path) (staticfield f);
	gen_value ctx e;
	newline ctx

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

(*
The generator must have a single "generate" definition that must accept a dir name a list of types. The types are already parsed and transformed in a nice AST ready to be consumed.
*)
let generate file types hres =
print_endline ("Doing lua in : " ^ file);
	let ctx = {
		buf = Buffer.create 16000;
		packages = Hashtbl.create 0;
		statics = [];
		inits = [];
		curclass = null_class;
		tabs = "";
		in_value = false;
		in_constructor = false;
		in_function = false;
		handle_break = false;
		debug = Plugin.defined "debug";
		id_counter = 0;
		curmethod = ("",false);
		commentcode = true;
	} in
	let t = Plugin.timer "generate lua" in
	print ctx "require \"Haxe\"";
	newline ctx;
	List.iter (generate_type ctx) types;

	print ctx "--\n";
	print ctx "-- Boot generation\n";
	print ctx "--\n";
	carriagereturn ctx;
	print ctx "lua.Boot.__res = {}\n";
	print ctx "lua.Boot.classes = {}\n";
	if ctx.debug then begin
		print ctx "%s = []" Transform.stack_var;
		newline ctx;
		print ctx "%s = []" Transform.exc_stack_var;
		newline ctx;
	end;
	Hashtbl.iter (fun name data ->
		print ctx "lua.Boot.__res[\"%s\"] = \"%s\"" (Ast.s_escape name) (Ast.s_escape data);
		newline ctx;
	) hres;
	print ctx "lua.Boot.__init()";
	newline ctx;
	List.iter (fun e ->
		gen_expr ctx e;
		newline ctx;
	) (List.rev ctx.inits);
	List.iter (generate_static ctx) (List.rev ctx.statics);



	(* Write out program *)
	let ch = open_out file in
	output_string ch (Buffer.contents ctx.buf);
	close_out ch;
	t()




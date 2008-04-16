(*
 *  haXe/PHP Compiler
 *  Copyright (c)2008 Franco Ponticelli
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

type method_name = {
  mutable mpath : module_path;
  mutable mname : string;
}

type context = {
  ch : out_channel;
  buf : Buffer.t;
  path : module_path;
  mutable get_sets : (string * bool,string) Hashtbl.t;
  mutable curclass : tclass;
  mutable tabs : string;
  mutable in_value : string option;
  mutable in_static : bool;
  mutable handle_break : bool;
  mutable imports : (string,string list list) Hashtbl.t;
  mutable required_paths : (string list * string) list;
  mutable locals : (string,string) PMap.t;
  mutable inv_locals : (string,string) PMap.t;
  mutable local_types : t list;
  mutable inits : texpr list;
  mutable constructor_block : bool;
  mutable quotes : int;
  mutable all_dynamic_methods: method_name list;
  mutable dynamic_methods: tclass_field list;
  mutable is_call : bool;
}

let rec escphp n =
  if n = 0 then "" else if n = 1 then "\\" else ("\\\\" ^ escphp (n-1))

(* TODO reduce relative pathes *)
let inc_path ctx path =
  let rec slashes n =
    if n = 0 then "" else ("../" ^ slashes (n-1))
  in
  match path with
  | ([],name) ->
    (slashes (List.length (fst ctx.path))) ^ name ^ ".php"
  | (pack,name) ->
    (slashes (List.length (fst ctx.path))) ^ String.concat "/" pack ^ "/" ^ name ^ ".php"

let rec register_required_path ctx path = match path with
  | [], "Float"
  | [], "Int"
  | [], "Array"
  | ["php"], "PhpMath__"
  | ["php"], "PhpDate__"
  | ["php"], "PhpXml__"
  | ["php"], "HException"
  | [], "String"
  | [], "Bool" -> ()
  | _, _ -> if not (List.exists(fun p -> p = path) ctx.required_paths) then
    ctx.required_paths <- path :: ctx.required_paths

let s_expr_name e =
  s_type (print_context()) e.etype

let s_type_name t =
  s_type (print_context()) t

let is_anonym_expr e =
  let s = s_expr_name e in
  if (String.length s > 1 && String.sub s 0 1 = "{") || (s_expr_name e) = "Dynamic" || (s_expr_name e) = "#Dynamic" then true else false

let is_unknown_expr e =
  let s = s_expr_name e in
  if (String.length s > 7 && String.sub s 0 7 = "Unknown<") then true else false

let is_array_expr e =
  let s = s_expr_name e in
  if (String.length s > 4 && String.sub s 0 5 = "Array") || (String.length s > 5 && String.sub s 0 6 = "#Array") then true else false

let is_string_expr e = (* match follow e.etype with TInst ({ cl_path = [],"String" },_) -> true | _ -> false *)
  if (s_expr_name e) = "String" || (s_expr_name e) = "#String" then true else false

let spr ctx s = Buffer.add_string ctx.buf s
let print ctx = Printf.kprintf (fun s -> Buffer.add_string ctx.buf s)

let s_path ctx path isextern p =
  if not isextern then register_required_path ctx path;
  match path with
  | ([],"List")              -> "HList"
  | ([],name)                -> name
  | (["php"],"PhpXml__")     -> "Xml"
  | (["php"],"PhpDate__")    -> "Date"
  | (["php"],"PhpMath__")    -> "Math"
  | (pack,name) ->
    try
      (match Hashtbl.find ctx.imports name with
      | [p] when p = pack ->
        String.concat "_" pack ^ "_" ^ name
      | packs ->
        if not (List.mem pack packs) then Hashtbl.replace ctx.imports name (pack :: packs);
        Ast.s_type_path path)
    with Not_found ->
      Hashtbl.add ctx.imports name [pack];
      String.concat "_" pack ^ "_" ^ name
	  
let s_path_haxe path =
	match fst path, snd path with
	| [], s -> s
	| el, s -> String.concat "." el ^ "." ^ s

(*
let s_is_by_ref s =
  String.length s > 9 && (String.sub s 0 9) = "__byref__"
 *)
	
let s_ident n =
  let suf = "h" in
(*
haxe reserved words that match php ones: break, case, class, continue, default, do, else, extends, for, function, if, new, return, static, switch, var, while, interface, implements, public, private, try, catch, throw
 *)
(* PHP only (for future use): cfunction, old_function *)
  match n with
  | "and" | "or" | "xor" | "__FILE__" | "exception" (* PHP 5 *) | "__LINE__" | "array"
  | "as" | "const" | "declare" | "die" | "echo"| "elseif" | "empty"
  | "enddeclare" | "endfor" | "endforeach" | "endif" | "endswitch"
  | "endwhile" | "eval" | "exit" | "foreach"| "global" | "include"
  | "include_once" | "isset" | "list" | "print" | "require" | "require_once"
  | "unset" | "use" | "__FUNCTION__" | "__CLASS__" | "__METHOD__" | "final" (* PHP 5 *)
  | "php_user_filter" (* PHP 5 *) | "protected" (* PHP 5 *) | "abstract" (* PHP 5 *)
  | "clone" (* PHP 5 *) -> suf ^ n
  | _ -> n

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
  let ch = open_out (String.concat "/" dir ^ "/" ^ snd path ^ ".php") in
  let imports = Hashtbl.create 0 in
  Hashtbl.add imports (snd path) [fst path];
  {
    tabs = "";
    ch = ch;
    path = path;
    buf = Buffer.create (1 lsl 14);
    in_value = None;
    in_static = false;
    handle_break = false;
    imports = imports;
    curclass = null_class;
    locals = PMap.empty;
    inv_locals = PMap.empty;
    local_types = [];
	required_paths = [];
    inits = [];
    get_sets = Hashtbl.create 0;
    constructor_block = false;
	quotes = 0;
	dynamic_methods = [];
	all_dynamic_methods = [];
	is_call = false;
  }

let unsupported = Typer.error "This expression cannot be generated to PHP"

let newline ctx =
  match Buffer.nth ctx.buf (Buffer.length ctx.buf - 1) with
  | '}' | '{' | ':' -> print ctx "\n%s" ctx.tabs
  | _ -> print ctx ";\n%s" ctx.tabs

let rec concat ctx s f = function
  | [] -> ()
  | [x] -> f x
  | x :: l ->
    f x;
    spr ctx s;
    concat ctx s f l

let open_block ctx =
  let oldt = ctx.tabs in
  ctx.tabs <- "\t" ^ ctx.tabs;
  (fun() -> ctx.tabs <- oldt)

let block = Transform.block

let parent e =
  match e.eexpr with
  | TParenthesis _ -> e
  | _ -> mk (TParenthesis e) e.etype e.epos

let close ctx =
  output_string ctx.ch "<?php\n";

  Hashtbl.iter (fun name paths ->
    List.iter (fun pack ->
      let path = pack, name in
	  register_required_path ctx path
    ) paths
  ) ctx.imports;

  List.iter (fun path ->
    if path <> ctx.path then output_string ctx.ch ("require_once dirname(__FILE__).'/" ^ inc_path ctx path ^ "';\n");
  ) (List.rev ctx.required_paths);
  output_string ctx.ch "\n";
  output_string ctx.ch (Buffer.contents ctx.buf);
  close_out ctx.ch

let save_locals ctx =
  let old = ctx.locals in
  (fun() -> ctx.locals <- old)

let define_local ctx l =
  let rec loop n =
    let name = (if n = 1 then s_ident l else l ^ string_of_int n) in
    if PMap.mem name ctx.inv_locals then
      loop (n+1)
    else begin
      ctx.locals <- PMap.add l name ctx.locals;
      ctx.inv_locals <- PMap.add name l ctx.inv_locals;
      name
    end
  in
  loop 1

(* TODO: review ... this is not working correctly *)
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
		let p = escphp ctx.quotes in
        print ctx "} catch(Exception %s$e) { if( %s$e->message != \"__break__\" ) throw %s$e; }" p p p;
      )

let this ctx =
  let p = escphp ctx.quotes in
  if ctx.in_value <> None then (p ^ "$__this") else (p ^ "$this")

let s_funarg ctx arg t p = 
  let byref = if String.length arg > 7 && String.sub arg 0 7 = "byref__" then "&" else "" in
  (match t with
  | TInst (c,_) -> (match c.cl_path with
	| ([], "Float")
	| ([], "String")
	| ([], "Array")
	| ([], "Int") 
	| ([], "Enum") 
	| ([], "Class") 
	| ([], "Bool") -> print ctx "%s%s$%s" byref (escphp ctx.quotes) arg
	| _ ->
		if c.cl_kind = KNormal then
			print ctx "%s %s%s$%s" (s_path ctx c.cl_path c.cl_extern p) byref (escphp ctx.quotes) arg
		else
			print ctx "%s%s$%s" byref (escphp ctx.quotes) arg)
  | _ -> print ctx "%s%s$%s" byref (escphp ctx.quotes) arg)

let is_in_dynamic_methods ctx e s =
	List.exists (fun dm ->
	  (* TODO: I agree, this is a mess ... but after ours of trials and errors I gave up; maybe in a calmer day *)
	  ((String.concat "." ((fst dm.mpath) @ ["#" ^ (snd dm.mpath)])) ^ "." ^ dm.mname) = (s_type_name e.etype ^ "." ^ s)
	) ctx.all_dynamic_methods

let is_dynamic_method f =
	match follow f.cf_type with
	| TFun _ when f.cf_expr = None -> true
	| _ ->
		(match f.cf_expr with
	    | Some { eexpr = TFunction fd } -> f.cf_set = NormalAccess
		| _ -> false)

let gen_function_header ctx name f params p =
  let old = ctx.in_value in
  let old_l = ctx.locals in
  let old_li = ctx.inv_locals in
  let old_t = ctx.local_types in
  ctx.in_value <- None;
  ctx.local_types <- List.map snd params @ ctx.local_types;
  (match name with
    | None ->
	  spr ctx "create_function('";
      concat ctx ", " (fun (arg,o,t) ->
        let arg = define_local ctx arg in
          s_funarg ctx arg t p;
          if o then spr ctx " = null";
        ) f.tf_args;
      print ctx "', '') "
	| Some n ->
      print ctx "function %s(" n;
      concat ctx ", " (fun (arg,o,t) ->
        let arg = define_local ctx arg in
          s_funarg ctx arg t p;
          if o then spr ctx " = null";
        ) f.tf_args;
      print ctx ") ");
  (fun () ->
    ctx.in_value <- old;
    ctx.locals <- old_l;
    ctx.inv_locals <- old_li;
    ctx.local_types <- old_t;
  )

let escape_bin s quotes =
  let b = Buffer.create 0 in
  for i = 0 to String.length s - 1 do
    match Char.code (String.unsafe_get s i) with
    | c when c < 32 -> Buffer.add_string b (Printf.sprintf "\\x%.2X" c)
	| c when c = Char.code('$') ->
	  Buffer.add_string b (escphp quotes);
	  Buffer.add_char b (Char.chr c)
    | c -> Buffer.add_char b (Char.chr c)
  done;
  Buffer.contents b

let gen_constant ctx p = function
  | TInt i -> print ctx "%ld" i
  | TFloat s -> spr ctx s
  | TString s -> 
	print ctx "%s\"%s%s\"" (escphp ctx.quotes) (escape_bin (Ast.s_escape s) (ctx.quotes+1)) (escphp ctx.quotes)
  | TBool b -> spr ctx (if b then "true" else "false")
  | TNull -> spr ctx "null"
  | TThis -> spr ctx (this ctx)
  | TSuper -> spr ctx "ERROR /* TODO: unexpected call to super in gen_constant */"

let rec gen_call ctx e el =
  match e.eexpr , el with
  | TConst TSuper , params ->
    (match ctx.curclass.cl_super with
	| None -> assert false
	| Some (c,_) ->
	  spr ctx "parent::__construct(";
	  concat ctx "," (gen_value ctx) params;
	  spr ctx ")";
	);
  | TField ({ eexpr = TConst TSuper },name) , params ->
	(match ctx.curclass.cl_super with
	| None -> assert false
	| Some (c,_) ->
	  print ctx "parent::%s(" (name);
	  concat ctx "," (gen_value ctx) params;
	  spr ctx ")";
	);
  | TCall (x,_) , el ->
    gen_value ctx e;
    spr ctx "(";
    concat ctx ", " (gen_value ctx) el;
    spr ctx ")";
  | TLocal "__call__" , { eexpr = TConst (TString code) } :: el ->
	spr ctx code;
	spr ctx "(";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")";
  | TLocal "__php__", [{ eexpr = TConst (TString code) }] ->
	spr ctx code
  | TLocal _, el
  | TFunction _, el ->
    ctx.is_call <- true;
	spr ctx "call_user_func(";
    gen_value ctx e;
	ctx.is_call <- false;
	if List.length el > 0 then begin
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	end else ();
	spr ctx ")";
  | _ ->
	ctx.is_call <- true;
    gen_value ctx e;
	ctx.is_call <- false;
    spr ctx "(";
    concat ctx ", " (gen_value ctx) el;
    spr ctx ")"

and gen_string_var ctx s e =
  match s with
  | "length" ->
    spr ctx "strlen(";
	gen_value ctx e;
	spr ctx ")"
  | _ ->
    unsupported e.epos;

and gen_array_var ctx s e =
  match s with
  | "length" ->
    spr ctx "count(";
	gen_value ctx e;
	spr ctx ")"
  | _ ->
    unsupported e.epos;

and gen_string_static_call ctx s e el =
  match s with
  | "fromCharCode" ->
    spr ctx "chr(";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")";
  | _ -> unsupported e.epos;

and gen_string_call ctx s e el =
  match s with
  | "substr" ->
    spr ctx "php_Boot::__substr(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "charAt" ->
    spr ctx "substr(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ", 1)"
  | "charCodeAt" ->
    spr ctx "ord(substr(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ", 1))"
  | "indexOf" ->
	spr ctx "php_Boot::__index_of(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "lastIndexOf" ->
    spr ctx "php_Boot::__last_index_of(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "split" ->
    spr ctx "split(";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ", ";
	gen_value ctx e;
	spr ctx ")"
  | "toLowerCase" ->
    spr ctx "strtolower(";
	gen_value ctx e;
	spr ctx ")"
  | "toUpperCase" ->
    spr ctx "strtoupper(";
	gen_value ctx e;
	spr ctx ")"
  | "toString" ->
	gen_value ctx e;
  | _ ->
    unsupported e.epos;

and gen_array_call ctx s e el =
  match s with
  | "push" ->
    spr ctx "array_push(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "concat" ->
    spr ctx "array_merge(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "join" ->
    spr ctx "join(";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ", ";
	gen_value ctx e;
	spr ctx ")"
  | "pop" ->
    spr ctx "array_pop(";
	gen_value ctx e;
	spr ctx ")"
  | "reverse" ->
    spr ctx "rsort(";
	gen_value ctx e;
	spr ctx ")"
  | "shift" ->
    spr ctx "array_shift(";
	gen_value ctx e;
	spr ctx ")"
  | "slice" ->
    spr ctx "php_Boot::__array_slice(array(&";
	gen_value ctx e;
	spr ctx "), ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "sort" ->
    spr ctx "php_Boot::__array_sort(array(&";
	gen_value ctx e;
	spr ctx "), ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "splice" ->
    spr ctx "php_Boot::__array_splice(array(&";
	gen_value ctx e;
	spr ctx "), ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "toString" ->
    spr ctx "'['.join(', ', ";
	gen_value ctx e;
	spr ctx ").']'"
  | "copy" ->
	gen_value ctx e;
  | "unshift" ->
    spr ctx "array_unshift(";
	gen_value ctx e;
	spr ctx ", ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "insert" ->
    spr ctx "php_Boot::__array_insert(array(&";
	gen_value ctx e;
	spr ctx "), ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "remove" ->
    spr ctx "php_Boot::__array_remove(array(&";
	gen_value ctx e;
	spr ctx "), ";
	concat ctx ", " (gen_value ctx) el;
	spr ctx ")"
  | "iterator" ->
    spr ctx "new HArrayIterator(";
	gen_value ctx e;
	spr ctx ")"
  | _ ->
    unsupported e.epos;
	
and gen_field_op ctx e = 
	match e.eexpr with
	| TField (f,s) ->
		(match follow e.etype with
		| TFun _ ->
			gen_field_access ctx true f s
		| _ ->
			gen_value_op ctx e)
	| _ ->
		gen_value_op ctx e

and gen_value_op ctx e =
  match e.eexpr with
  | TBinop (op,_,_) when op = Ast.OpAnd || op = Ast.OpOr || op = Ast.OpXor ->
    spr ctx "(";
    gen_value ctx e;
    spr ctx ")";
  | _ ->
    gen_value ctx e

and is_static t =
  match follow t with
    | TAnon a -> (match !(a.a_status) with
	  | Statics c -> true
	  | _ -> false)
    | _ -> false

and gen_member_access ctx isvar e s =
	match follow e.etype with
	| TAnon a -> 
		(match !(a.a_status) with
		| EnumStatics _
		| Statics _ -> print ctx "::%s%s" (if isvar then ((escphp ctx.quotes) ^ "$") else "") (s_ident s)
		| _ -> print ctx "->%s" (s_ident s))
	| _ -> print ctx "->%s" (s_ident s)
	
and gen_field_access ctx isvar e s =
	match e.eexpr with
	| TTypeExpr t ->
		spr ctx (s_path ctx (t_path t) false e.epos);
		gen_member_access ctx isvar e s
	| TLocal _ ->
		gen_expr ctx e;
		print ctx "->%s" (s_ident s)
	| _ -> 
		gen_expr ctx e;
		gen_member_access ctx isvar e s

and gen_dynamic_function ctx isstatic name f params p =
  let old = ctx.in_value in
  let old_l = ctx.locals in
  let old_li = ctx.inv_locals in
  let old_t = ctx.local_types in
  ctx.in_value <- None;
  ctx.local_types <- List.map snd params @ ctx.local_types;
  print ctx "function %s(" name;
  concat ctx ", " (fun (arg,o,t) ->
	let arg = define_local ctx arg in
	  s_funarg ctx arg t p;
	  if o then spr ctx " = null";
	) f.tf_args;
(*
  if isstatic then begin
	  print ctx ") {\n\t\tif(self::$%s == null)\n"  name;
	  print ctx "\t\t\tself::$%s = php_Boot::__closure(array(\"\"), \"" name;
	  ctx.quotes <- ctx.quotes + 1;
	  concat ctx "," (fun (arg,o,t) ->
	    s_funarg ctx arg t p;
	    if o then spr ctx " = null";
	  ) f.tf_args;
	  ctx.quotes <- ctx.quotes - 1;

	  print ctx "\", \"";
	  ctx.quotes <- ctx.quotes + 1;
	  gen_expr ctx (block f.tf_expr);
	  ctx.quotes <- ctx.quotes - 1;
	  print ctx "\");\n";
  end else begin
  *)
	  spr ctx ") {";
(*  end; *)

  if (List.length f.tf_args) > 0 then begin
	if isstatic then
		print ctx " return call_user_func(self::$%s, "  name
	else
		print ctx " return call_user_func($this->%s, "  name;

	concat ctx ", " (fun (arg,o,t) ->
	  spr ctx ((escphp ctx.quotes) ^ "$" ^ arg)
	) f.tf_args;
	print ctx "); }";
  end else if isstatic then
	print ctx " return call_user_func(self::$%s); }"  name
  else
	print ctx " return call_user_func($this->%s); }"  name;

  newline ctx;
  if isstatic then
	print ctx "public static $%s = null" name
  else
	print ctx "public $%s = null" name;
  ctx.in_value <- old;
  ctx.locals <- old_l;
  ctx.inv_locals <- old_li;
  ctx.local_types <- old_t

and gen_function ctx name f params p =
  let old = ctx.in_value in
  let old_l = ctx.locals in
  let old_li = ctx.inv_locals in
  let old_t = ctx.local_types in
  ctx.in_value <- None;
  ctx.local_types <- List.map snd params @ ctx.local_types;
  print ctx "function %s(" name;
  concat ctx ", " (fun (arg,o,t) ->
	let arg = define_local ctx arg in
	  s_funarg ctx arg t p;
	  if o then spr ctx " = null";
	) f.tf_args;
  print ctx ") ";
  gen_expr ctx (block f.tf_expr);
  ctx.in_value <- old;
  ctx.locals <- old_l;
  ctx.inv_locals <- old_li;
  ctx.local_types <- old_t

and gen_inline_function ctx f params p =
  let old = ctx.in_value in
  let old_l = ctx.locals in
  let old_li = ctx.inv_locals in
  let old_t = ctx.local_types in
  ctx.in_value <- Some "closure";
  ctx.local_types <- List.map snd params @ ctx.local_types;
  spr ctx "php_Boot::__closure(array(";

  let p = escphp ctx.quotes in
  let c = ref 0 in
  PMap.iter (fun n _ ->
    if !c > 0 then spr ctx ", ";
	incr c;
    print ctx "%s\"%s%s\" => &%s$%s" p n p p n;
  ) old_l;

  print ctx "), %s\"" p;
  ctx.quotes <- ctx.quotes + 1;
  concat ctx "," (fun (arg,o,t) ->
	let arg = define_local ctx arg in
	  s_funarg ctx arg t p;
	  if o then spr ctx " = null";
	) f.tf_args;
  ctx.quotes <- ctx.quotes - 1;
  print ctx "%s\", %s\"" p p;
  ctx.quotes <- ctx.quotes + 1;
  gen_expr ctx (block f.tf_expr);
  ctx.quotes <- ctx.quotes - 1;
  print ctx "%s\")" p;
  ctx.in_value <- old;
  ctx.locals <- old_l;
  ctx.inv_locals <- old_li;
  ctx.local_types <- old_t

and gen_expr ctx e =
  match e.eexpr with
  | TConst c ->
    gen_constant ctx e.epos c
  | TLocal s ->
    spr ctx ((escphp ctx.quotes) ^ "$" ^ (try PMap.find s ctx.locals with Not_found -> Typer.error ("Unknown local " ^ s) e.epos))
  | TEnumField (en,s) ->
    register_required_path ctx en.e_path;
	(match (try PMap.find s en.e_constrs with Not_found -> Typer.error ("Unknown local " ^ s) e.epos).ef_type with
    | TFun (args,_) -> print ctx "%s::%s" (s_path ctx en.e_path en.e_extern e.epos) (s_ident s)
	| _ -> print ctx "%s::%s$%s" (s_path ctx en.e_path en.e_extern e.epos) (escphp ctx.quotes) (s_ident s))
  | TArray (e1,e2) ->
    gen_value ctx e1;
    spr ctx "[";
    gen_value ctx e2;
    spr ctx "]";
  | TBinop (op,e1,e2) ->
	(match op with
	| Ast.OpAssign ->
	    (match e1.eexpr with
		| TArray(te1, te2) ->
			spr ctx "php_Boot::__array_set(array(&";
			gen_value ctx te1;
			spr ctx "), ";
			gen_value ctx te2;
			spr ctx ", ";
			gen_value ctx e2;
			spr ctx ")";
(*		| TField (ef1,s) ->
			(match follow e.etype with
			| TFun _ ->
				gen_field_access ctx true ef1 s;
				spr ctx " = ";
				gen_value_op ctx e2;
			| _ ->
				gen_value_op ctx e1;
				spr ctx " = ";
				gen_value_op ctx e2;
			);
*)
		| _ ->
			gen_field_op ctx e1;
			spr ctx " = ";
			gen_value_op ctx e2;)
	| Ast.OpAssignOp(Ast.OpAdd) when (is_string_expr e1 || is_string_expr e2) ->
		gen_value_op ctx e1;
	    spr ctx " .= ";
	    gen_value_op ctx e2;
	| Ast.OpAdd when (is_string_expr e1 || is_string_expr e2) ->
		gen_value_op ctx e1;
	    spr ctx ".";
	    gen_value_op ctx e2;
	| Ast.OpAssignOp(Ast.OpShl) ->
		gen_value_op ctx e1;
	    spr ctx " <<= ";
	    gen_value_op ctx e2;
	| Ast.OpShl ->
	    gen_value_op ctx e1;
	    spr ctx " << ";
	    gen_value_op ctx e2;
	| Ast.OpAssignOp(Ast.OpUShr) ->
		gen_value_op ctx e1;
	    spr ctx " = ";
	    spr ctx "php_Boot::__shift_right(";
	    gen_value_op ctx e1;
	    spr ctx ", ";
	    gen_value_op ctx e2;
		spr ctx ")";
	| Ast.OpUShr ->
	    spr ctx "php_Boot::__shift_right(";
	    gen_value_op ctx e1;
	    spr ctx ", ";
	    gen_value_op ctx e2;
		spr ctx ")";
	| Ast.OpNotEq
	| Ast.OpEq ->
		let s_op = if op = Ast.OpNotEq then " != " else " == " in
		let s_phop = if op = Ast.OpNotEq then " !== " else " === " in
		if
			   e1.eexpr = TConst (TNull)
			|| e2.eexpr = TConst (TNull)
		then begin	
			gen_field_op ctx e1;
			spr ctx s_phop;
		    gen_field_op ctx e2;
		end else if
		       (((s_expr_name e1) = "Int" || (s_expr_name e1) = "Float" || (s_expr_name e1) = "Null<Int>" || (s_expr_name e1) = "Null<Float>")
			   && ((s_expr_name e1) = "Int" || (s_expr_name e1) = "Float" || (s_expr_name e1) = "Null<Int>" || (s_expr_name e1) = "Null<Float>"))
			|| (is_unknown_expr e1 && is_unknown_expr e2)
			|| is_anonym_expr e1
			|| is_anonym_expr e2
		then begin
			if op = Ast.OpNotEq then spr ctx "!";
			spr ctx "php_Boot::__equal(";
			gen_field_op ctx e1;
			spr ctx ", ";
			gen_field_op ctx e2;
			spr ctx ")";
		end else if
			   e1.etype == e2.etype
			|| (match e1.eexpr with | TConst _ | TLocal _ | TArray _  | TNew _ -> true | _ -> false)
			|| (match e2.eexpr with | TConst _ | TLocal _ | TArray _  | TNew _ -> true | _ -> false) 
			|| is_string_expr e1
			|| is_string_expr e2
			|| is_array_expr e1
			|| is_array_expr e2
			|| is_anonym_expr e1
			|| is_anonym_expr e2
			|| is_unknown_expr e1
			|| is_unknown_expr e2
		then begin
			gen_field_op ctx e1;
			spr ctx s_phop;
		    gen_field_op ctx e2;
		end else begin
			gen_field_op ctx e1;
			spr ctx s_op;
			gen_field_op ctx e2;
		end
	| _ ->
		gen_value_op ctx e1;
	    print ctx " %s " (Ast.s_binop op);
	    gen_value_op ctx e2;
	);    
  | TField (e1,s) ->
	(match follow e.etype with
	| TFun _ ->
	  let p = escphp ctx.quotes in
	  (if ctx.is_call then
	    gen_field_access ctx false e1 s
	  else if is_in_dynamic_methods ctx e1 s then
	  	gen_field_access ctx true e1 s
	  else begin
		spr ctx "array(";
		(match e1.eexpr with
		| TTypeExpr t ->
			print ctx "%s\"" p;
			spr ctx (s_path ctx (t_path t) false e1.epos);
			print ctx "%s\"" p
		| _ -> gen_expr ctx e1);
		print ctx ", %s\"%s%s\")" p s p;
	  end);
	| TMono _ ->
	  if ctx.is_call then (
(*		spr ctx "/*MONOCALL*/"; *)
		gen_field_access ctx false e1 s 
	  ) else  (
(*		spr ctx "/*MONO*/";  *)
		gen_field_access ctx true e1 s )
	| _ ->
	  if is_string_expr e1 then gen_string_var ctx s e1
	  else if is_array_expr e1 then gen_array_var ctx s e1
	  else (* spr ctx "/*OUT*/"; *) gen_field_access ctx true e1 s
	)

  | TTypeExpr t ->
    let p = escphp ctx.quotes in
(*	if is_string_expr e || is_array_expr e then
	print ctx "%s\"%s%s\"" p (s_path ctx (t_path t) false e.epos) p
	else *)
	register_required_path ctx (t_path t);
	print ctx "php_Boot::__qtype(%s\"%s%s\")" p (s_path_haxe (t_path t)) p
  | TParenthesis e ->
    spr ctx "(";
    gen_value ctx e;
    spr ctx ")";
  | TReturn eo ->
    (match eo with
    | None ->
      spr ctx "return"
    | Some e when (match follow e.etype with TEnum({ e_path = [],"Void" },[]) -> true | _ -> false) ->
      gen_value ctx e;
      newline ctx;
      spr ctx "return"
    | Some e ->
      spr ctx "return ";
      gen_value ctx e);
  | TBreak ->
    if ctx.in_value <> None then unsupported e.epos;
    if ctx.handle_break then spr ctx "throw new Exception(\"__break__\")" else spr ctx "break"
  | TContinue ->
    if ctx.in_value <> None then unsupported e.epos;
    spr ctx "continue"
  | TBlock [] ->
    spr ctx ""
  | TBlock el ->
    let b = save_locals ctx in
    print ctx "{";
    let bend = open_block ctx in
    let cb = (if not ctx.constructor_block then
      (fun () -> ())
    else begin
      ctx.constructor_block <- false;
	  if List.length ctx.dynamic_methods > 0 then newline ctx else spr ctx " ";
	  List.iter (fun (f) ->
		let name = f.cf_name in
	  	match f.cf_expr with
	    | Some { eexpr = TFunction fd } ->
			print ctx "$this->%s = php_Boot::__closure(array(\"__this\" => &$this), \"" name;
			ctx.quotes <- ctx.quotes + 1;
			concat ctx "," (fun (arg,o,t) ->
			let arg = define_local ctx arg in
			  s_funarg ctx arg t e.epos;
		      if o then spr ctx " = null";
		    ) fd.tf_args;
			ctx.quotes <- ctx.quotes - 1;
			
			print ctx "\", \"";
			let old = ctx.in_value in
			ctx.in_value <- Some name;
			ctx.quotes <- ctx.quotes + 1;
			gen_expr ctx (block fd.tf_expr);
			ctx.quotes <- ctx.quotes - 1;
			ctx.in_value <- old;
			print ctx "\")";
			newline ctx;
		| _ -> ()
	  ) ctx.dynamic_methods;
      print ctx "if( !%s::$skip_constructor ) {" (s_path ctx (["php"],"Boot") false e.epos);
            (fun() -> print ctx "}")
    end) in
    List.iter (fun e -> newline ctx; gen_expr ctx e) el;
    bend();
    newline ctx;
    cb();
    print ctx "}";
    b();
  | TFunction f ->
    let old = ctx.in_static in
    ctx.in_static <- true;
    gen_inline_function ctx f [] e.epos;
    ctx.in_static <- old
  | TCall (e,el) ->
    (match e.eexpr with
	  | TField (e1,s) when is_array_expr e1 -> gen_array_call ctx s e1 el
	  | TField (e1,s) when is_static e1.etype && is_string_expr e1 -> gen_string_static_call ctx s e1 el
	  | TField (e1,s) when is_string_expr e1 -> gen_string_call ctx s e1 el
	  | _ -> 
	    gen_call ctx e el)
  | TArrayDecl el ->
    spr ctx "array(";
    concat ctx ", " (gen_value ctx) el;
    spr ctx ")";
  | TThrow e ->
    spr ctx "throw new php_HException(";
    gen_value ctx e;
	spr ctx ")";
  | TVars [] ->
    ()
  | TVars vl ->
    spr ctx ((escphp ctx.quotes) ^ "$");
    concat ctx ("; " ^ (escphp ctx.quotes) ^ "$") (fun (n,t,v) ->
      let n = define_local ctx n in
      match v with
      | None -> print ctx "%s = null" n
      | Some e ->
        print ctx "%s = " n;
        gen_value ctx e
    ) vl;
  | TNew (c,_,el) ->
	(match c.cl_path with
	| [], "String" -> 
      concat ctx "" (gen_value ctx) el
	| [], "Array" -> 
	  spr ctx "array(";
      concat ctx ", " (gen_value ctx) el;
      spr ctx ")"
	| _, _ ->
      print ctx "new %s(" (s_path ctx c.cl_path c.cl_extern e.epos);
      concat ctx ", " (gen_value ctx) el;
      spr ctx ")")
  | TIf (cond,e,eelse) ->
    spr ctx "if";
    gen_value ctx (parent cond);
    spr ctx " ";
    gen_expr ctx e;
    (match eelse with
    | None -> ()
	| Some e when e.eexpr = TConst(TNull) -> ()
    | Some e ->
      newline ctx;
      spr ctx "else ";
      gen_expr ctx e);
  | TUnop (op,Ast.Prefix,e) ->
    spr ctx (Ast.s_unop op);
    gen_value ctx e
  | TUnop (op,Ast.Postfix,e) ->
    gen_value ctx e;
    spr ctx (Ast.s_unop op)
  | TWhile (cond,e,Ast.NormalWhile) ->
    let handle_break = handle_break ctx e in
    spr ctx "while";
    gen_value ctx (parent cond);
    spr ctx " ";
    gen_expr ctx e;
    handle_break();
  | TWhile (cond,e,Ast.DoWhile) ->
    let handle_break = handle_break ctx e in
    spr ctx "do ";
    gen_expr ctx e;
    spr ctx " while";
    gen_value ctx (parent cond);
    handle_break();
  | TObjectDecl fields ->
    spr ctx "php_Boot::__anonymous(array(";
	let p = escphp ctx.quotes in
    concat ctx ", " (fun (f,e) -> print ctx "%s\"%s%s\" => " p f p; gen_value ctx e) fields;
    spr ctx "))"
  | TFor (v,t,it,e) ->
    let handle_break = handle_break ctx e in
    let b = save_locals ctx in
    let tmp = define_local ctx "__it__" in
    let v = define_local ctx v in
	let p = escphp ctx.quotes in
	print ctx "%s$%s = " p tmp;
	gen_value ctx it;
	newline ctx;
	print ctx "while(%s$%s->hasNext()) {" p tmp;
	newline ctx;
	print ctx "%s$%s = %s$%s->next()" p v p tmp;
    newline ctx;
    gen_expr ctx e;
    newline ctx;
    spr ctx "}";
    b();
    handle_break();
  | TTry (e,catchs) ->
    spr ctx "try ";
    gen_expr ctx (block e);
	let ex = define_local ctx "__e__" in
	print ctx "catch(php_HException %s$%s) {" (escphp ctx.quotes) ex;
	let p = escphp ctx.quotes in
	let first = ref true in
    List.iter (fun (v,t,e) ->
		let ev = define_local ctx v in
        newline ctx;
        let b = save_locals ctx in
	    if not !first then spr ctx "else ";
		(match follow t with
		| TEnum (te,_) -> (match snd te.e_path with
			| "Bool"   -> print ctx "if(is_bool(%s$%s = %s$%s->e))"        p ev p ex
			| _ -> print ctx "if((%s$%s = %s$%s->e) instanceof %s)"        p ev p ex (s_path ctx te.e_path te.e_extern e.epos));
			gen_expr ctx (block e);
		| TInst (tc,_) -> (match snd tc.cl_path with
			| "Int"    -> print ctx "if(is_int(%s$%s = %s$%s->e))"         p ev p ex
			| "Float"  -> print ctx "if(is_numeric(%s$%s = %s$%s->e))"     p ev p ex
			| "String" -> print ctx "if(is_string(%s$%s = %s$%s->e))"      p ev p ex
			| "Array"  -> print ctx "if(is_array(%s$%s = %s$%s->e))"       p ev p ex
			| _        -> print ctx "if((%s$%s = %s$%s->e) instanceof %s)" p ev p ex (s_path ctx tc.cl_path tc.cl_extern e.epos));
			gen_expr ctx (block e);
		| TFun _
		| TLazy _
		| TType _
		| TAnon _ ->
			assert false
		| TMono _
		| TDynamic _ ->
			print ctx "{ %s$%s = %s$%s->e" p ev p ex;
			newline ctx;
			gen_expr ctx (block e);
			spr ctx "}");
        b();
	    first := false;
    ) catchs;
	spr ctx "}";
  | TMatch (e,_,cases,def) ->
    let b = save_locals ctx in
    let tmp = define_local ctx "__t__" in
    print ctx "%s$%s = " (escphp ctx.quotes) tmp;
    gen_value ctx e;
    newline ctx;
    print ctx "switch(%s$%s->index) {" (escphp ctx.quotes) tmp;
    newline ctx;
    List.iter (fun (cl,params,e) ->
      List.iter (fun c ->
        print ctx "case %d:" c;
        newline ctx;
      ) cl;
      let b = save_locals ctx in
      (match params with
      | None | Some [] -> ()
      | Some l ->
        let n = ref (-1) in
        let l = List.fold_left (fun acc (v,t) -> incr n; match v with None -> acc | Some v -> (v,t,!n) :: acc) [] l in
        match l with
        | [] -> ()
        | l ->
          concat ctx "; " (fun (v,t,n) ->
            let v = define_local ctx v in
            print ctx "%s$%s = %s$%s->params[%d]" (escphp ctx.quotes) v (escphp ctx.quotes) tmp n;
          ) l;
          newline ctx);
      gen_expr ctx (block e);
      print ctx "break";
      newline ctx;
      b()
    ) cases;
    (match def with
    | None -> ()
    | Some e ->
      spr ctx "default:";
      gen_expr ctx (block e);
      print ctx "break";
      newline ctx;
    );
    spr ctx "}";
    b()
  | TSwitch (e,cases,def) ->
    spr ctx "switch";
    gen_value ctx (parent e);
    spr ctx " {";
    newline ctx;
    List.iter (fun (el,e2) ->
      List.iter (fun e ->
        spr ctx "case ";
        gen_value ctx e;
        spr ctx ":";
      ) el;
      gen_expr ctx (block e2);
      print ctx "break";
      newline ctx;
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

and gen_value ctx e =
  let assign e =
    mk (TBinop (Ast.OpAssign,
      mk (TLocal (match ctx.in_value with None -> assert false | Some v -> "__r__")) t_dynamic e.epos,
      e
    )) e.etype e.epos
  in
  let value block =
    let old = ctx.in_value in
    let locs = save_locals ctx in
    let tmp = define_local ctx "__r__" in
    ctx.in_value <- Some tmp;
    let b = if block then begin
      print ctx "eval(%s\"" (escphp ctx.quotes);
	  ctx.quotes <- (ctx.quotes + 1);
      let b = open_block ctx in
      b
    end else
      (fun() -> ())
    in
    (fun() ->
      if block then begin
        newline ctx;
        print ctx "return %s$%s" (escphp ctx.quotes) tmp;
        b();
        newline ctx;
		ctx.quotes <- (ctx.quotes - 1);
        print ctx "%s\")" (escphp ctx.quotes);
      end;
      ctx.in_value <- old;
      locs();
    )
  in
  match e.eexpr with
  | TCall ({ eexpr = TLocal "__keys__" },_) | TCall ({ eexpr = TLocal "__hkeys__" },_) ->
    let v = value true in
    gen_expr ctx e;
    v()
  | TTypeExpr _
  | TConst _
  | TLocal _
  | TEnumField _
  | TArray _
  | TBinop _
  | TField _
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
        spr ctx "return null";
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
    spr ctx "(";
    gen_value ctx cond;
    spr ctx " ? ";
    gen_value ctx e;
    spr ctx " : ";
    (match eo with
    | None -> spr ctx "null"
    | Some e -> gen_value ctx e);
    spr ctx ")"
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
    let v = value true in
    gen_expr ctx (mk (TTry (assign b,
      List.map (fun (v,t,e) -> v, t , assign e) catchs
    )) e.etype e.epos);
    v()

let generate_field ctx static f =
  newline ctx;
  ctx.in_static <- static;
  ctx.locals <- PMap.empty;
  ctx.inv_locals <- PMap.empty;
  let public = f.cf_public || Hashtbl.mem ctx.get_sets (f.cf_name,static) || (f.cf_name = "main" && static) || f.cf_name = "__resolve" in
  let rights = (if public then "public" else "/*protected*/ public") ^ (if static then " static" else "") in
  let p = ctx.curclass.cl_pos in
  match f.cf_expr with
  | Some { eexpr = TFunction fd } ->
	spr ctx (rights ^ " ");
	(match f.cf_set with
	| NormalAccess when (match fd.tf_expr.eexpr with | TBlock _ -> true | _ -> false) ->
	  gen_dynamic_function ctx static (s_ident f.cf_name) fd f.cf_params p
	| _ ->
      gen_function ctx (s_ident f.cf_name) fd f.cf_params p
	);
  | _ ->
    if ctx.curclass.cl_interface then
      match follow f.cf_type with
      | TFun (args,r) ->
(*		if s_is_by_ref f.cf_name then 
			print ctx "function &%s(" f.cf_name
		else *)
			print ctx "function %s(" f.cf_name;
        concat ctx ", " (fun (arg,o,t) ->
(*		  if s_is_by_ref arg then 
			spr ctx "&"; *)
		  s_funarg ctx arg t p;
          if o then spr ctx " = null";
        ) args;
        print ctx ")";
      | _ -> spr ctx "//"; ()
    else if (match f.cf_get with MethodAccess m -> true | _ -> match f.cf_set with MethodAccess m -> true | _ -> false) then begin
	  match f.cf_get, f.cf_set with 
	  | MethodAccess m1, MethodAccess m2 -> spr ctx "//";
	  | _, _ ->
	    print ctx "%s $%s" rights (s_ident f.cf_name);
    end else begin
      print ctx "%s $%s" rights (s_ident f.cf_name);
      match f.cf_expr with
      | None -> ()
      | Some e ->
		match e.eexpr with
		| TConst _ -> 
			print ctx " = ";
			gen_value ctx e
		| _ -> ()
    end

let generate_static_field_assign ctx path f =
	ctx.in_static <- true;

	let p = ctx.curclass.cl_pos in
	if not ctx.curclass.cl_interface then
		(match f.cf_expr with
		| None -> ()
		| Some e ->
			match e.eexpr with
			| TConst _ -> ()
			| TFunction fd ->
				(match f.cf_set with
				| NormalAccess when (match fd.tf_expr.eexpr with | TBlock _ -> true | _ -> false) ->
					newline ctx;
					print ctx "%s::$%s = " (s_path ctx path false p) (s_ident f.cf_name);
					gen_value ctx e
				| _ -> ())
			| _ ->
				newline ctx;
				print ctx "%s::$%s = " (s_path ctx path false p) (s_ident f.cf_name);
				gen_value ctx e)

let define_getset ctx stat f =
  let def name =
    Hashtbl.add ctx.get_sets (name,stat) f.cf_name
  in
  (match f.cf_get with MethodAccess m -> def m | _ -> ());
  (match f.cf_set with MethodAccess m -> def m | _ -> ())

let rec super_has_dynamic c =
  match c.cl_super with
    | None -> false
	| Some (csup, _) -> (match csup.cl_dynamic with
		| Some _ -> true
		| _ -> super_has_dynamic csup)

let generate_class ctx all_dynamic_methods c =
  let requires_constructor = ref true in
  ctx.curclass <- c;
  ctx.all_dynamic_methods <- all_dynamic_methods;
  List.iter (define_getset ctx false) c.cl_ordered_fields;
  List.iter (define_getset ctx true) c.cl_ordered_statics;
  ctx.local_types <- List.map snd c.cl_types;

  register_required_path ctx (["php"], "Boot");

  print ctx "%s %s " (if c.cl_interface then "interface" else "class") (s_path ctx c.cl_path c.cl_extern c.cl_pos);
  (match c.cl_super with
  | None -> ()
  | Some (csup,_) ->
    requires_constructor := false;
	print ctx "extends %s " (s_path ctx csup.cl_path csup.cl_extern c.cl_pos));
  (match c.cl_implements with
  | [] -> ()
  | l ->
    spr ctx (if c.cl_interface then "extends " else "implements ");
    concat ctx ", " (fun (i,_) ->
	  print ctx "%s" (s_path ctx i.cl_path i.cl_extern c.cl_pos)) l);
  spr ctx "{";

  let get_dynamic_methods = List.filter is_dynamic_method c.cl_ordered_fields in

  if not ctx.curclass.cl_interface then ctx.dynamic_methods <- get_dynamic_methods;

  let cl = open_block ctx in
  (match c.cl_constructor with
  | None ->
	if !requires_constructor && not c.cl_interface then begin
		newline ctx;
		spr ctx "public function __construct(){}"
	end;
  | Some f ->
    let f = { f with
      cf_name = "__construct";
      cf_public = true;
    } in
    ctx.constructor_block <- true;
    generate_field ctx false f;
  );

  List.iter (generate_field ctx false) c.cl_ordered_fields;

  (match c.cl_dynamic with
  | Some _ when not c.cl_interface && not (super_has_dynamic c) ->
	newline ctx;
  	spr ctx "private $__dynamics = array();\n\tpublic function &__get($n) {\n\t\tif(isset($this->__dynamics[$n]))\n\t\t\treturn $this->__dynamics[$n];\n\t\t}\n\tpublic function __set($n, $v) {\n\t\t$this->__dynamics[$n] = $v;\n\t}"
  | _ -> ()
  );
  if List.length ctx.dynamic_methods > 0 then begin
	newline ctx;
    spr ctx "public function __call($m, $a) {\n\t\tif(property_exists($this, $m) && is_callable($this->$m))\n\t\t\treturn call_user_func_array($this->$m, $a);\n\t\telse if(isset($this->__dynamics[$m]) && is_callable($this->__dynamics[$m]))\n\t\t\treturn call_user_func_array($this->__dynamics[$m], $a);\n\t\telse\n\t\t\tthrow new php_HException('NotAFunction', 'Unable to call '.$m);\n\t}";
  end;

  List.iter (generate_field ctx true) c.cl_ordered_statics;
  
  cl();
  newline ctx;
  print ctx "}"

let generate_main ctx c =
  (match c.cl_ordered_statics with
  | [{ cf_expr = Some e }] ->
    gen_value ctx e;
  | _ -> assert false);
  newline ctx

let generate_enum ctx e =
  ctx.local_types <- List.map snd e.e_types;
  let pack = open_block ctx in
  let ename = s_path ctx e.e_path e.e_extern e.e_pos in

  register_required_path ctx (["php"], "Boot");

  print ctx "class %s extends enum {" ename;
  let cl = open_block ctx in
  PMap.iter (fun _ c ->
    newline ctx;
    match c.ef_type with
    | TFun (args,_) ->
      print ctx "public static function %s($" c.ef_name;
      concat ctx ", $" (fun (a,o,t) ->
        spr ctx a;
        if o then spr ctx " = null";
      ) args;
      spr ctx ") {";
      print ctx " return new %s(\"%s\", %d, array($" ename c.ef_name c.ef_index;
      concat ctx ", $" (fun (a,_,_) -> spr ctx a) args;
      print ctx ")); }";
    | _ ->
	  print ctx "public static $%s" c.ef_name;
  ) e.e_constrs;
  cl();
  newline ctx;
  print ctx "}";

  PMap.iter (fun _ c ->
    match c.ef_type with
    | TFun (args,_) ->
      ();
    | _ ->
	  newline ctx;
      print ctx "%s::$%s = new %s(\"%s\", %d)" ename c.ef_name ename c.ef_name  c.ef_index;
  ) e.e_constrs;

  pack();
  newline ctx

let generate dir types =
  let all_dynamic_methods = ref [] in
  List.iter (fun t ->
    (match t with
    | TClassDecl c ->
	  let dynamic_methods_names lst =
		List.map (fun fd -> {
          mpath = c.cl_path;
	      mname = fd.cf_name;
        }) (List.filter is_dynamic_method lst)
	  in
	  all_dynamic_methods := dynamic_methods_names c.cl_ordered_fields @ !all_dynamic_methods;
	  all_dynamic_methods := dynamic_methods_names c.cl_ordered_statics @ !all_dynamic_methods
	| _ -> ())
  ) types;
  List.iter (fun t ->
    (match t with
    | TClassDecl c ->
      let c = (match c.cl_path with
        | ["php"],"PhpXml__"    -> { c with cl_path = [],"Xml" }
		| ["php"],"PhpDate__"   -> { c with cl_path = [],"Date" }
        | ["php"],"PhpMath__"   -> { c with cl_path = [],"Math" }
        | _ -> c
      ) in
      if c.cl_extern then
        ()
      else (match c.cl_path with
      | [], "@Main" ->
		let ctx = init dir ([], "index") in
		generate_main ctx c;
        close ctx;
      | _ ->
        let ctx = init dir c.cl_path in
				
		let cp = s_path ctx c.cl_path c.cl_extern c.cl_pos in

        generate_class ctx !all_dynamic_methods c;

        (match c.cl_init with
        | None -> ()
        | Some e ->
			newline ctx;
			gen_expr ctx e);

		if c.cl_interface then begin
			newline ctx;
			print ctx "php_Boot::__register_type(new _interfacedef(\"%s\", \"%s\"))" cp (s_path_haxe c.cl_path);
		end else begin
			newline ctx;
			print ctx "php_Boot::__register_type(new _rclassdef(\"%s\", \"%s\"))" cp (s_path_haxe c.cl_path);
		end;

		List.iter (generate_static_field_assign ctx c.cl_path) c.cl_ordered_statics;
		newline ctx;

		close ctx);
    | TEnumDecl e ->
      if e.e_extern then
        ()
      else
        let ctx = init dir e.e_path in
        generate_enum ctx e;

		print ctx "php_Boot::__register_type(new _enumdef(\"%s\", \"%s\"))" (s_path ctx e.e_path false e.e_pos) (s_path_haxe e.e_path);
		newline ctx;

        close ctx
    | TTypeDecl t ->
      ());
  ) types
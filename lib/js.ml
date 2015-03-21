(* Js_of_ocaml library
 * http://www.ocsigen.org/js_of_ocaml/
 * Copyright (C) 2010 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

type +'a t

type (-'a, +'b) meth_callback

module Unsafe = struct
  external variable : string -> 'a = "caml_js_var"

  type any
  external inject : 'a -> any = "%identity"
  external coerce : _ t -> _ t = "%identity"

  external get : 'a -> 'b -> 'c = "caml_js_get"
  external set : 'a -> 'b -> 'c -> unit = "caml_js_set"
  external delete : 'a -> 'b -> unit = "caml_js_delete"
  external call : 'a -> 'b -> any array -> 'c = "caml_js_call"
  external fun_call : 'a -> any array -> 'b = "caml_js_fun_call"
  external meth_call : 'a -> string -> any array -> 'b = "caml_js_meth_call"
  external new_obj : 'a -> any array -> 'b = "caml_js_new"

  external obj : (string * any) array -> 'a = "caml_js_object"

  external equals : 'a -> 'b -> bool = "caml_js_equals"

  external pure_expr : (unit -> 'a) -> 'a = "caml_js_pure_expr"

  external eval_string : string -> 'a = "caml_js_eval_string"

  external js_expr : string -> 'a = "caml_js_expr"

  external pure_js_expr : string -> 'a = "caml_pure_js_expr"

  let global = variable "joo_global_object"

  external callback : ('a -> 'b) -> ('c, 'a -> 'b) meth_callback = "%identity"
  external meth_callback : ('b -> 'a) -> ('b, 'a) meth_callback = "caml_js_wrap_meth_callback_unsafe"
end

(****)

type 'a opt = 'a
type 'a optdef = 'a

external debugger : unit -> unit = "debugger"

let null : 'a opt = Unsafe.pure_js_expr "null"
external some : 'a -> 'a opt = "%identity"

let undefined : 'a optdef = Unsafe.pure_js_expr "undefined"
external def : 'a -> 'a optdef = "%identity"

module type OPT = sig
  type 'a t
  val empty : 'a t
  val return : 'a -> 'a t
  val map : 'a t -> ('a -> 'b) -> 'b t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val test : 'a t -> bool
  val iter : 'a t -> ('a -> unit) -> unit
  val case : 'a t -> (unit -> 'b) -> ('a -> 'b) -> 'b
  val get : 'a t -> (unit -> 'a) -> 'a
  val option : 'a option -> 'a t
  val to_option : 'a t -> 'a option
end

module Opt : OPT with type 'a t = 'a opt = struct
  type 'a t = 'a opt
  let empty = null
  let return = some
  let map x f = if Unsafe.equals x null then null else some (f x)
  let bind x f = if Unsafe.equals x null then null else f x
  let test x = not (Unsafe.equals x null)
  let iter x f = if not (Unsafe.equals x null) then f x
  let case x f g = if Unsafe.equals x null then f () else g x
  let get x f = if Unsafe.equals x null then f () else x
  let option x = match x with None -> empty | Some x -> return x
  let to_option x = case x (fun () -> None) (fun x -> Some x)
end

module Optdef : OPT with type 'a t = 'a optdef = struct
  type 'a t = 'a opt
  let empty = undefined
  let return = def
  let map x f = if x == undefined then undefined else some (f x)
  let bind x f = if x == undefined then undefined else f x
  let test x = x != undefined
  let iter x f = if x != undefined then f x
  let case x f g = if x == undefined then f () else g x
  let get x f = if x == undefined then f () else x
  let option x = match x with None -> empty | Some x -> return x
  let to_option x = case x (fun () -> None) (fun x -> Some x)
end

(****)

let coerce x f g = Opt.get (f x) (fun () -> g x)
let coerce_opt x f g = Opt.get (Opt.bind x f) (fun () -> g x)

(****)

type +'a meth
type +'a gen_prop
type 'a readonly_prop = <get : 'a> gen_prop
type 'a writeonly_prop = <set : 'a -> unit> gen_prop
type 'a prop = <get : 'a; set : 'a -> unit> gen_prop
type 'a optdef_prop = <get : 'a optdef; set : 'a -> unit> gen_prop

type +'a constr

(****)

type 'a callback = (unit, 'a) meth_callback

external wrap_callback : ('a -> 'b) -> ('c, 'a -> 'b) meth_callback = "caml_js_wrap_callback"
external wrap_meth_callback : ('a -> 'b) -> ('a, 'b) meth_callback = "caml_js_wrap_meth_callback"

(****)

let _true = Unsafe.pure_js_expr "true"
let _false = Unsafe.pure_js_expr "false"

type match_result_handle
type string_array

class type js_string = object
  method toString : js_string t meth
  method valueOf : js_string t meth
  method charAt : int -> js_string t meth
  method charCodeAt : int -> float meth (* This may return NaN... *)
  method concat : js_string t -> js_string t meth
  method concat_2 : js_string t -> js_string t -> js_string t meth
  method concat_3 :
    js_string t -> js_string t -> js_string t -> js_string t meth
  method concat_4 :
    js_string t -> js_string t -> js_string t -> js_string t ->
    js_string t meth
  method indexOf : js_string t -> int meth
  method indexOf_from : js_string t -> int -> int meth
  method lastIndexOf : js_string t -> int meth
  method lastIndexOf_from : js_string t -> int -> int meth
  method localeCompare : js_string t -> float meth
  method _match : regExp t -> match_result_handle t opt meth
  method replace : regExp t -> js_string t -> js_string t meth
  method replace_string : js_string t -> js_string t -> js_string t meth
  method search : regExp t -> int meth
  method slice : int -> int -> js_string t meth
  method slice_end : int -> js_string t meth
  method split : js_string t -> string_array t meth
  method split_limited : js_string t -> int -> string_array t meth
  method split_regExp : regExp t -> string_array t meth
  method split_regExpLimited : regExp t -> int -> string_array t meth
  method substring : int -> int -> js_string t meth
  method substring_toEnd : int -> js_string t meth
  method toLowerCase : js_string t meth
  method toLocaleLowerCase : js_string t meth
  method toUpperCase : js_string t meth
  method toLocaleUpperCase : js_string t meth
  method length : int readonly_prop
end

and regExp = object
  method exec : js_string t -> match_result_handle t opt meth
  method test : js_string t -> bool t meth
  method toString : js_string t meth
  method source : js_string t readonly_prop
  method global : bool t readonly_prop
  method ignoreCase : bool t readonly_prop
  method multiline : bool t readonly_prop
  method lastIndex : int prop
end

class type string_constr = object
  method fromCharCode : int -> js_string t meth
end

let string_constr = Unsafe.global##.String

let regExp = Unsafe.global##.RegExp
let regExp_copy = regExp
let regExp_withFlags = regExp

class type ['a] js_array = object
  method toString : js_string t meth
  method toLocaleString : js_string t meth
  method concat : 'a js_array t -> 'a js_array t meth
  method join : js_string t -> js_string t meth
  method pop : 'a optdef meth
  method push : 'a -> int meth
  method push_2 : 'a -> 'a -> int meth
  method push_3 : 'a -> 'a -> 'a -> int meth
  method push_4 : 'a -> 'a -> 'a -> 'a -> int meth
  method reverse : 'a js_array t meth
  method shift : 'a optdef meth
  method slice : int -> int -> 'a js_array t meth
  method slice_end : int -> 'a js_array t meth
  method sort : ('a -> 'a -> float) callback -> 'a js_array t meth
  method sort_asStrings : 'a js_array t meth
  method splice : int -> int -> 'a js_array t meth
  method splice_1 : int -> int -> 'a -> 'a js_array t meth
  method splice_2 : int -> int -> 'a -> 'a -> 'a js_array t meth
  method splice_3 : int -> int -> 'a -> 'a -> 'a -> 'a js_array t meth
  method splice_4 : int -> int -> 'a -> 'a -> 'a -> 'a -> 'a js_array t meth
  method unshift : 'a -> int meth
  method unshift_2 : 'a -> 'a -> int meth
  method unshift_3 : 'a -> 'a -> 'a -> int meth
  method unshift_4 : 'a -> 'a -> 'a -> 'a -> int meth

  method some : ('a -> int -> 'a js_array t -> bool t ) -> bool t meth
  method every : ('a -> int -> 'a js_array t -> bool t ) -> bool t meth
  method forEach : ('a -> int -> 'a js_array t -> unit ) -> unit meth
  method map : ('a -> int -> 'a js_array t -> 'b) -> 'b js_array t meth
  method filter : ('a -> int -> 'a js_array t -> bool t) -> 'a js_array t meth
  method reduce_init : ('b -> 'a -> int -> 'a js_array t -> 'b) -> 'b -> 'b meth
  method reduce : ('a -> 'a -> int -> 'a js_array t -> 'a) -> 'a meth
  method reduceRight_init : ('b -> 'a -> int -> 'a js_array t -> 'b) -> 'b -> 'b meth
  method reduceRight : ('a -> 'a -> int -> 'a js_array t -> 'a) -> 'a meth

  method length : int prop
end

let array_constructor = Unsafe.global##.Array
let array_empty = array_constructor
let array_length = array_constructor

let array_get : 'a #js_array t -> int -> 'a optdef = Unsafe.get
let array_set : 'a #js_array t -> int -> 'a -> unit = Unsafe.set

class type match_result = object
  inherit [js_string t] js_array
  method index : int readonly_prop
  method input : js_string t readonly_prop
end

let str_array : string_array t -> js_string t js_array t = Unsafe.coerce
let match_result : match_result_handle t -> match_result t =
  Unsafe.coerce

class type number = object
  method toString : js_string t meth
  method toString_radix : int -> js_string t meth
  method toLocaleString : js_string t meth
  method toFixed : int -> js_string t meth
  method toExponential : js_string t meth
  method toExponential_digits : int -> js_string t meth
  method toPrecision : int -> js_string meth t
end

external number_of_float : float -> number t = "caml_js_from_float"
external float_of_number : number t -> float = "caml_js_to_float"

class type date = object
  method toString : js_string t meth
  method toDateString : js_string t meth
  method toTimeString : js_string t meth
  method toLocaleString : js_string t meth
  method toLocaleDateString : js_string t meth
  method toLocaleTimeString : js_string t meth
  method valueOf : float meth
  method getTime : float meth
  method getFullYear : int meth
  method getUTCFullYear : int meth
  method getMonth : int meth
  method getUTCMonth : int meth
  method getDate : int meth
  method getUTCDate : int meth
  method getDay : int meth
  method getUTCDay : int meth
  method getHours : int meth
  method getUTCHours : int meth
  method getMinutes : int meth
  method getUTCMinutes : int meth
  method getSeconds : int meth
  method getUTCSeconds : int meth
  method getMilliseconds : int meth
  method getUTCMilliseconds : int meth
  method getTimezoneOffset : int meth
  method setTime : float -> float meth
  method setFullYear : int -> float meth
  method setUTCFullYear : int -> float meth
  method setMonth : int -> float meth
  method setUTCMonth : int -> float meth
  method setDate : int -> float meth
  method setUTCDate : int -> float meth
  method setDay : int -> float meth
  method setUTCDay : int -> float meth
  method setHours : int -> float meth
  method setUTCHours : int -> float meth
  method setMinutes : int -> float meth
  method setUTCMinutes : int -> float meth
  method setSeconds : int -> float meth
  method setUTCSeconds : int -> float meth
  method setMilliseconds : int -> float meth
  method setUTCMilliseconds : int -> float meth
  method toUTCString : js_string t meth
  method toISOString : js_string t meth
  method toJSON : 'a -> js_string t meth
end

class type date_constr = object
  method parse : js_string t -> float meth
  method _UTC_month : int -> int -> float meth
  method _UTC_day : int -> int -> float meth
  method _UTC_hour : int -> int -> int -> int -> float meth
  method _UTC_min : int -> int -> int -> int -> int -> float meth
  method _UTC_sec : int -> int -> int -> int -> int -> int -> float meth
  method _UTC_ms :
    int -> int -> int -> int -> int -> int -> int -> float meth
(*
  method now : float meth
*)
end

let date_constr = Unsafe.global##.Date
let date : date_constr t = date_constr
let date_now : date t constr = date_constr
let date_fromTimeValue : (float -> date t) constr = date_constr
let date_month : (int -> int -> date t) constr = date_constr
let date_day : (int -> int -> int -> date t) constr = date_constr
let date_hour : (int -> int -> int -> int -> date t) constr = date_constr
let date_min : (int -> int -> int -> int -> int -> date t) constr = date_constr
let date_sec : (int -> int -> int -> int -> int -> int -> date t) constr =
  date_constr
let date_ms :
  (int -> int -> int -> int -> int -> int -> int -> date t) constr =
  date_constr

class type math = object
  method random : float meth
end

let math = Unsafe.global##.Math


class type error = object
  method name : js_string t prop
  method message : js_string t prop
  method stack : js_string t optdef prop
  method toString : js_string t meth
end

exception Error of error t
let error_constr = Unsafe.global##.Error
let _ = Callback.register_exception "jsError" (Error (Unsafe.obj [||]))

class type json = object
  method parse : js_string t -> 'a meth
  method stringify: 'a -> js_string t meth
end

let _JSON : json t = Unsafe.global##.JSON


let decodeURI (s : js_string t) : js_string t =
  Unsafe.fun_call (Unsafe.global##.decodeURI) [|Unsafe.inject s|]
let decodeURIComponent (s : js_string t) : js_string t =
  Unsafe.fun_call (Unsafe.global##.decodeURIComponent) [|Unsafe.inject s|]
let encodeURI (s : js_string t) : js_string t =
  Unsafe.fun_call (Unsafe.global##.encodeURI) [|Unsafe.inject s|]
let encodeURIComponent (s : js_string t) : js_string t =
  Unsafe.fun_call (Unsafe.global##.encodeURIComponent) [|Unsafe.inject s|]
let escape (s : js_string t) : js_string t =
  Unsafe.fun_call (Unsafe.global##.escape) [|Unsafe.inject s|]
let unescape (s : js_string t) : js_string t =
  Unsafe.fun_call (Unsafe.global##.unescape) [|Unsafe.inject s|]

external bool : bool -> bool t = "caml_js_from_bool"
external to_bool : bool t -> bool = "caml_js_to_bool"
external string : string -> js_string t = "caml_js_from_string"
external to_string : js_string t -> string = "caml_js_to_string"
external array : 'a array -> 'a js_array t = "caml_js_from_array"
external to_array : 'a js_array t -> 'a array = "caml_js_to_array"
external bytestring : string -> js_string t = "caml_bytes_of_string"
external to_bytestring : js_string t -> string = "caml_js_to_byte_string"

external typeof : < .. > t -> js_string t = "caml_js_typeof"
external instanceof : 'a -> 'b -> bool = "caml_js_instanceof"

let isNaN (i : 'a) : bool =
  to_bool (Unsafe.fun_call (Unsafe.global##.isNaN) [|Unsafe.inject i|])

let parseInt (s : js_string t) : int =
  let s = Unsafe.fun_call (Unsafe.global##.parseInt) [|Unsafe.inject s|] in
  if isNaN s
  then failwith "parseInt"
  else s

let parseFloat (s : js_string t) : float =
  let s = Unsafe.fun_call (Unsafe.global##.parseFloat) [|Unsafe.inject s|] in
  if isNaN s
  then failwith "parseFloat"
  else s

let _ =
  Printexc.register_printer
    (function Error e -> Some (to_string (e##toString)) | _ -> None)
let _ =
  Printexc.register_printer
    (fun e ->
       if instanceof e array_constructor then None
       else Some (to_string ((Obj.magic e)##toString)))

let string_of_error e = to_string (e##toString)

(****)

(* DEPRECATED *)

type float_prop = float prop
external float : float -> float = "%identity"
external to_float : float -> float = "%identity"

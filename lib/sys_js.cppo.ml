(* Js_of_ocaml library
 * http://www.ocsigen.org/js_of_ocaml/
 * Copyright (C) 2014 Hugo Heuzard
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


external register_file': string -> string -> unit = "caml_fs_register"
external caml_fs_register_autoload : string -> (Js.js_string Js.t Js.js_array Js.t -> int -> bool Js.t) Js.callback -> unit = "caml_fs_register_autoload"

external set_channel_output' : out_channel -> (Js.js_string Js.t -> unit) Js.callback -> unit = "caml_ml_set_channel_output"

let register_file ~name ~content = register_file' name content

let register_autoload ~path f =
  let f' path pos =
    let prefix = Js.to_string ((path##slice 0 pos)##join(Js.string"/")) in
    let suffix = Js.to_string ((path##slice_end pos)##join(Js.string"/")) in
    match f (prefix, suffix)  with
    | None -> Js._false
    | Some c ->
      let filename = Filename.concat prefix suffix in
      register_file ~name:filename ~content:c;
      Js._true in
  caml_fs_register_autoload path (Js.wrap_callback f')

let set_channel_flusher (out_channel : out_channel) (f : string -> unit) =
  let f' : (Js.js_string Js.t -> unit) Js.callback = Js.wrap_callback (fun s -> f (Js.to_string s)) in
  set_channel_output' out_channel f'

external file_content : string -> string = "caml_fs_file_content"

(* The version string is found in file ../VERSION *)

let js_of_ocaml_version = STRINGIFY(JSOO_VERSION)

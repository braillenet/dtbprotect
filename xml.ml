(*
 * dtbprotect - A Digital Talking Book encryption program.
 *
 * Copyright (C) 2009-2010 by The dtbprotect developers (see AUTHORS file).
 *
 * dtbprotect comes with ABSOLUTELY NO WARRANTY.
 *
 * This is free software, placed under the terms of the
 * GNU General Public License, as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any
 * later version. Please see the file GPLV2 for details.
 *
 * Web Page: http://www.serveur-helene.org/
 *)

include Xmlm

let string_of_signal (s : signal) = match s with
  | `Dtd _ -> "DTD"
  | `El_start ((ns,n),_) ->
    "start tag ns=" ^ ns ^ " n=" ^ n
  | `El_end -> "end tag"
  | `Data d -> ("Data " ^ d)

let debug_input_signals = ref false

let input_signal i =
  let s = input i in
  if !debug_input_signals then Printf.fprintf stderr "%s\n" (string_of_signal s);
  s

let input_list input_element i =
  let rec f () = match input_element i with
    | None -> []
    | Some e -> e::( f () ) 
  in f ()  

let indent o d =
  let n = 2 * d in
  let s = String.make n ' ' in
  output o (`Data s) 

let nl o =
  output o (`Data "\n")

let output_start_tag o t =
  indent o (get_depth o);
  output o (`El_start t);
  nl o

let output_end_tag o =
  let d = get_depth o in
  if d > 0 then
  begin
    indent o (d-1);
    output o `El_end;
    if get_depth o > 0 then nl o
  end else output o `El_end

let output_empty_element o tag =
  indent o (get_depth o);
  output o (`El_start tag);
  output o `El_end;
  nl o

let output_text_element o tag content =
  indent o (get_depth o);
  output o (`El_start tag);
  output o (`Data content);
  output o `El_end;
  nl o

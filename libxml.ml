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

type node
type document
type namespace

external init : unit -> unit = "libxmlml_init"

external xmlNewDoc : string -> document =
  "libxmlml_xmlNewDoc"

external xmlNewNode : string -> document option -> namespace option -> node =
  "libxmlml_xmlNewNode"

external xmlNewNs : node -> Namespaces.t -> namespace =
  "libxmlml_xmlNewNs"
external xmlSetNs : node -> namespace -> unit =
  "libxmlml_xmlSetNs"

external xmlNewProp : node -> string -> string -> unit =
  "libxmlml_xmlNewProp"

external xmlNewChild : node -> namespace option -> string -> string option -> node =
  "libxmlml_xmlNewChild"

external xmlDocSetRootElement : document -> node -> unit =
  "libxmlml_xmlDocSetRootElement"
external xmlSearchNsByHref : document -> node -> string -> namespace =
  "libxmlml_xmlSearchNsByHref"
type rawNode_ =
  | Leaf_ of Xml.tag * string
  | Node_ of Xml.tag * (node list)

type rawNode =
  | Leaf of Xml.tag * string
  | Node of Xml.tag * (rawNode list)

external openNode_ : node -> rawNode_ = "libxmlml_openNode"

let rec openNode n = match (openNode_ n) with
  | Leaf_ (tag, str) -> Leaf (tag, str)
  | Node_ (tag, nodelist) -> Node (tag, (List.map openNode nodelist))

let findNode p n =
  let rec f n = match (openNode_ n) with
    | Leaf_ (tag, str) when p tag -> n
    | Leaf_ _ -> raise Not_found
    | Node_ (tag, _) when p tag -> n
    | Node_ (_, l) -> g l
  and g = function
    | [] -> raise Not_found 
    | h::t -> try (f h) with Not_found -> (g t)   
  in f n

let remove p t0 =
  let rec f = function
    | Leaf _ as leaf -> leaf
    | Node (tag, nl) -> Node (tag, g nl)
  and g = function
    | [] -> []
    | n::ns when p n -> g ns
    | n::ns -> (f n) :: (g ns) 
  in f t0

let findAndRemove p t0 =
  let rec f = function
    | Leaf _ -> raise Not_found
    | Node (tag, nodelist) ->
      let (n, nl) = g nodelist in
      (n, Node (tag, nl))
  and g = function
    | [] -> raise Not_found
    | n::ns when p n -> (n, ns)
    | n::ns ->
      try
        begin
          let (result, tree) = f n in
          (result, tree::ns)
        end
      with Not_found ->
      let (n', ns') = g ns in
      (n', n::ns')
  in f t0

let clean t0 =
  let p = function
    | Leaf( ( ( "", "text"), []), "\n") -> true
    | _ -> false
  in
  remove p t0

let simplify t0 =
  let rec f = function
    | Leaf _ as leaf -> leaf
    | Node (tag, ([Leaf ((("","text"),[]),str)])) -> Leaf (tag, str)
    | Node (tag, nodelist) -> Node (tag, g nodelist)
  and g = function
    | [] -> []
    | n::ns -> (f n)::(g ns) 
  in f t0

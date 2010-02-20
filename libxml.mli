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

val init : unit -> unit
val xmlNewDoc : string -> document
val xmlNewNode : string -> document option -> namespace option -> node
val xmlNewNs : node -> Namespaces.t -> namespace
val xmlSetNs : node -> namespace -> unit
val xmlNewProp : node -> string -> string -> unit
val xmlNewChild : node -> namespace option -> string -> string option -> node
val xmlDocSetRootElement : document -> node -> unit
val xmlSearchNsByHref : document -> node -> string -> namespace

type rawNode_ =
  | Leaf_ of Xml.tag * string
  | Node_ of Xml.tag * (node list)

type rawNode =
  | Leaf of Xml.tag * string
  | Node of Xml.tag * (rawNode list)

val openNode_ : node -> rawNode_
val openNode : node -> rawNode
val findNode : (Xml.tag -> bool) -> node -> node
val remove : (rawNode -> bool) -> rawNode -> rawNode
val findAndRemove : (rawNode -> bool) -> rawNode -> rawNode * rawNode
val clean : rawNode -> rawNode
val simplify : rawNode -> rawNode

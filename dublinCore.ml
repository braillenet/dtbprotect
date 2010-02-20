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

type dc_tag =
  | Title
  | Creator
  | Subject
  | Description
  | Publisher
  | Contributor
  | Date
  | Type
  | Format
  | Identifier
  | Source
  | Language
  | Relation
  | Coverage
  | Rights

type dc_element = {
  dc_tag : dc_tag;
  dc_content : string;
  dc_attributes : Xml.attribute list
}

type dc_metadata = dc_element list

let tag_of_string = function
  | "Title" -> Title
  | "Creator" -> Creator
  | "Subject" -> Subject
  | "Description" -> Description
  | "Publisher" -> Publisher
  | "Contributor" -> Contributor
  | "Date" -> Date
  | "Type" -> Type
  | "Format" -> Format
  | "Identifier" -> Identifier
  | "Source" -> Source
  | "Language" -> Language
  | "Relation" -> Relation
  | "Coverage" -> Coverage
  | "Rights" -> Rights
  | _ -> raise (Invalid_argument "DublinCore.tag_of_string")

let string_of_tag = function
  | Title -> "Title"
  | Creator -> "Creator"
  | Subject -> "Subject"
  | Description -> "Description"
  | Publisher -> "Publisher"
  | Contributor -> "Contributor"
  | Date -> "Date"
  | Type -> "Type"
  | Format -> "Format"
  | Identifier -> "Identifier"
  | Source -> "Source"
  | Language -> "Language"
  | Relation -> "Relation"
  | Coverage -> "Coverage"
  | Rights -> "Rights"

let is_dc_name (ns, n) = ns=Namespaces.uri Namespaces.dc

let input_dc_element i = match Xml.peek i with
  | `El_start ((ns, n), a) when ns=Namespaces.uri Namespaces.dc ->
    begin
      ignore (Xml.input_signal i);
      let s1 = Xml.input_signal i in
      let s2 = Xml.input_signal i in
      match (s1, s2) with
        | (`Data s, `El_end) ->
          Some {
            dc_tag = tag_of_string n;
            dc_content = s;
            dc_attributes = a
          }
        | _ -> failwith "Malformed dublin core element"
    end
  | _ -> None

let output_dc_element o e =
  let name = (Namespaces.uri Namespaces.dc), (string_of_tag e.dc_tag) in
  let t = name, e.dc_attributes in
  Xml.output_text_element o t e.dc_content  
 
let input_dc_metadata i =
  let checkdcElements l = true
  in match Xml.input_signal i with
    | `El_start (el, _) when el=Elements.oeb_dc_metadata ->
      let l = Xml.input_list input_dc_element i in
      assert (checkdcElements l);
      assert ((Xml.input_signal i) = `El_end);
      l
    | _ -> failwith "Malformed XML document"

let output_dc_metadata o dc =
  let dc_attr = Namespaces.declaration_attribute Namespaces.dc in 
  Xml.output_start_tag o (Elements.oeb_dc_metadata, [dc_attr]);
  List.iter (output_dc_element o) dc;
  Xml.output_end_tag o (* </dc-metadata> *)

let find tag dc =
  let p e = e.dc_tag = tag in
  List.find p dc 

let content e = e.dc_content

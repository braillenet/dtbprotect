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

val tag_of_string : string -> dc_tag
val string_of_tag : dc_tag -> string
val input_dc_metadata : Xml.input -> dc_metadata
val output_dc_metadata : Xml.output -> dc_metadata -> unit
val find : dc_tag -> dc_metadata -> dc_element
val content : dc_element -> string

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

(* Package manipulaiton module *)

type manifestItem = {
  href : string;
  id : string;
  mediaType : string
}

type manifest = manifestItem list

type ncx = {
  ncx_href : string;
  ncx_mediatype : string
}

type tour = string

type guide = string list

type t = {
  dtd : string;
  uniqueIdentifier : string;
  dc : DublinCore.dc_metadata;
  x : Dtb.dtb_metadata option;
  manifest : manifest;
  ncx : ncx;  
  spine : string list;
  tours : tour list;
  guide : guide
}

val load : string -> t
val save : string -> t -> unit

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

type t = {
  uri : string;
  prefix : string
}

let uri ns = ns.uri
let prefix ns = ns.prefix

let declaration_attribute ns =
  (Xml.ns_xmlns,ns.prefix), ns.uri

let default_namespace_attribute ns =
  (Xml.ns_xmlns, "xmlns"), ns.uri

let dba = {
  uri = "http://www.daisy.org/DRM/2005/BookAuthorization";
  prefix = "dba"
}

let ds = {
  uri = "http://www.w3.org/2000/09/xmldsig#";
  prefix = "ds"
}

let odrld = {
  uri = "http://odrl.net/1.1/ODRL-DD";
  prefix = "odrld"
}

let odrlx  = {
  uri = "http://odrl.net/1.1/ODRL-EX";
  prefix = "odrlx"
}

let xe = {
  uri = "http://www.w3.org/2001/04/xmlenc#";
  prefix = "xe"
}

let xsi = {
  uri = "http://www.w3.org/2001/XMLSchema-instance";
  prefix = "xsi"
}

let dc = {
  uri = "http://purl.org/dc/elements/1.1/";
  prefix = "dc"
}

let oeb = {
  uri = "http://openebook.org/namespaces/oeb-package/1.0/";
  prefix = "oeb"
}

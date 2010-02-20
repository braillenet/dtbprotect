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

open Namespaces

let make_name namespace local_name = (namespace.uri, local_name)

let ds_KeyInfo = make_name ds "KeyInfo"
let ds_KeyName = make_name ds "KeyName"

let xe_CipherValue = make_name xe "CipherValue"
let xe_EncryptedKey = make_name xe "EncryptedKey"

let dba_Issuer = make_name dba "Issuer"
let dba_uid = make_name dba "uid"
let dba_Book = make_name dba "Book"
let dba_ContentKey = make_name dba "ContentKey"
let dba_media = make_name dba "media"
let dba_Keys = make_name dba "Keys"
let dba_BookAuthorization = make_name dba "BookAuthorization"

let oeb_meta = make_name oeb "meta"
let oeb_metadata = make_name oeb "metadata"
let oeb_manifest = make_name oeb "manifest"
let oeb_item = make_name oeb "item"
let oeb_unique_identifier = "", "unique-identifier"
let oeb_spine = make_name oeb "spine"
let oeb_itemref = make_name oeb "itemref"
let oeb_package = make_name oeb "package"
let oeb_dc_metadata = make_name oeb "dc-metadata"
let oeb_idref = make_name oeb "idref"
let oeb_x_metadata = make_name oeb "x-metadata"

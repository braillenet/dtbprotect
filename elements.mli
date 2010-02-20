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

val ds_KeyInfo : Xml.name
val ds_KeyName : Xml.name

val xe_CipherValue : Xml.name
val xe_EncryptedKey : Xml.name

val dba_Issuer : Xml.name
val dba_uid : Xml.name
val dba_Book : Xml.name
val dba_ContentKey : Xml.name
val dba_media : Xml.name
val dba_Keys : Xml.name
val dba_BookAuthorization : Xml.name

val oeb_metadata : Xml.name
val oeb_meta : Xml.name
val oeb_manifest : Xml.name
val oeb_item : Xml.name
val oeb_unique_identifier : Xml.name
val oeb_spine : Xml.name
val oeb_itemref : Xml.name
val oeb_package : Xml.name
val oeb_dc_metadata : Xml.name
val oeb_idref : Xml.name
val oeb_x_metadata : Xml.name

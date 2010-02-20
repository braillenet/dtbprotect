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

module Key = struct
  type t (* The type of keys: defined in C *)
  type keyDataFormat =
    | UnknownFormat
    | BinaryFormat
    | PEMFormat
    | DERFormat
    | Pkcs8PemFormat
    | Pkcs8DEerFormat
    | Pkcs12Format
    | CertPemFormat
    | CertDerFormat

  type keyDataId
  type keyDataType = int
  let keyDataTypeUnknown = 0 
  let keyDataTypeNone = keyDataTypeUnknown 
  let keyDataTypePublic = 0x0001
  let keyDataTypePrivate = 0x0002
  let keyDataTypeSymmetric = 0x0004
  let keyDataTypeSession = 0x0008 
  let keyDataTypePermanent = 0x0010

  external generate : keyDataId option -> int -> keyDataType -> t
  = "xmlsecml_xmlSecKeyGenerate"
  external setName : t -> string -> unit = "xmlsecml_xmlSecKeySetName"
  external readBinaryFile : keyDataId option -> string -> t =
    "xmlsecml_xmlSecKeyReadBinaryFile"
end (* Key *)

module KeyManager = struct
  type t (* A key manager *)
  external create : unit -> t = "xmlsecml_xmlSecKeysMngrCreate"
  external init : t -> int = "xmlsecml_xmlSecCryptoAppDefaultKeysMngrInit"
  external adoptKey : t -> Key.t -> int = "xmlsecml_xmlSecCryptoAppDefaultKeysMngrAdoptKey"
  external destroy : t -> unit = "xmlsecml_xmlSecKeysMngrDestroy"
end (* KeyManager *)

module Transform = struct
  type id =
    | AES128CBC
    | RSAPKCS1
end (* Transform *)

module Templates = struct
  type t = Libxml.node (* The type of templates *)
  type tdata = {
    td_document : Libxml.document option;
    td_encMethodId : Transform.id;
    td_id : string option;
    td_type : string option;
    td_mimeType : string option;
    td_encoding : string option
  }
  
  type encryptedKeyData = {
    ekd_encMethodId : Transform.id;
    ekd_id : string option;
    ekd_type : string option;
    ekd_recipient : string option
  }
  
  external encDataCreate : tdata -> t = "xmlsecml_xmlSecTmplEncDataCreate"
  external encDataEnsureCipherValue : t -> Libxml.node =
    "xmlsecml_xmlSecTmplEncDataEnsureCipherValue"
  external encDataEnsureKeyInfo : t -> string option -> Libxml.node =
    "xmlsecml_xmlSecTmplEncDataEnsureKeyInfo"
  external keyInfoAddEncryptedKey : Libxml.node -> encryptedKeyData -> Libxml.node =
    "xmlsecml_xmlSecTmplKeyInfoAddEncryptedKey"
  external keyInfoAddKeyName : Libxml.node -> string -> Libxml.node =
    "xmlsecml_xmlSecTmplKeyInfoAddKeyName"
end (* Templates *) 

module Xmlenc = struct
  type encCtx
  
  external encCtxCreate_with_key : KeyManager.t option -> Key.t -> encCtx =
    "xmlsecml_xmlEncCtxCreate_with_key"
  external setCarriedKeyName : encCtx -> string -> unit =
    "xmlsecml_setCarriedKeyName"
  external encCtxXmlEncrypt : encCtx -> Templates.t -> Libxml.node -> int =
    "xmlsecml_encCtxXmlEncrypt"
end (* Xmlenc *)

module App = struct
  external init : unit -> int
    = "xmlsecml_xmlSecInit"
  external cryptoAppInit : string option -> int
    = "xmlsecml_xmlSecCryptoAppInit"
  external cryptoInit : unit -> int
    = "xmlsecml_xmlSecCryptoInit"

  external cryptoShutdown : unit -> unit = "xmlsecml_xmlSecCryptoShutdown"
  external cryptoAppShutdown : unit -> unit = "xmlsecml_xmlSecCryptoAppShutdown"
  external shutdown : unit -> unit = "xmlsecml_xmlSecShutdown"
  
  external cryptoAppKeyLoad : string -> Key.keyDataFormat -> Key.t
  = "xmlsecml_xmlSecCryptoAppKeyLoad"
end (* App *)

external encryptFile : Key.t -> string -> string -> unit =
  "encryptFile"

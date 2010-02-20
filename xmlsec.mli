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

module Key : sig
  type t (* The type of keys *) 
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
  val keyDataTypeUnknown : keyDataType
  val keyDataTypeNone : keyDataType
  val keyDataTypePublic : keyDataType
  val keyDataTypePrivate : keyDataType
  val keyDataTypeSymmetric : keyDataType  
  val keyDataTypeSession : keyDataType
  val keyDataTypePermanent : keyDataType

  val generate : keyDataId option -> int -> keyDataType -> t
  val setName : t -> string -> unit
  val readBinaryFile : keyDataId option -> string -> t
end (* Key *)

module KeyManager : sig
  type t (* A key manager *)
  val create : unit -> t
  val init : t -> int
  val adoptKey : t -> Key.t -> int
  val destroy : t -> unit
end (* KeyManager *)

module Transform : sig
  type id =
    | AES128CBC
    | RSAPKCS1
end (* Transform *)

module Templates : sig
  type t = Libxml.node (* Templates are libxml nodes, but a distinct type makes the code more readable *)
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
  
  val encDataCreate : tdata -> t
  val encDataEnsureCipherValue : t -> Libxml.node 
  val encDataEnsureKeyInfo : t -> string option -> Libxml.node 
  val keyInfoAddEncryptedKey : Libxml.node -> encryptedKeyData -> Libxml.node
  val keyInfoAddKeyName : Libxml.node -> string -> Libxml.node
end (* Templates *)

module Xmlenc : sig
  type encCtx
  
  val encCtxCreate_with_key : KeyManager.t option -> Key.t -> encCtx
  val setCarriedKeyName : encCtx -> string -> unit
  val encCtxXmlEncrypt : encCtx -> Templates.t -> Libxml.node -> int
end (* Xmlenc *)

module App : sig
  val init : unit -> int
  val cryptoAppInit : string option -> int
  val cryptoInit : unit -> int

  val cryptoShutdown : unit -> unit
  val cryptoAppShutdown : unit -> unit
  val shutdown : unit -> unit

  val cryptoAppKeyLoad : string -> Key.keyDataFormat -> Key.t
end (* App *)

val encryptFile : Key.t -> string -> string -> unit

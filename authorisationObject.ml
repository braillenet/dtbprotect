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

open Elements

type t = {
  bookIdentifier : string;
  issuerName : string;
  issuerIdentifier : string;
  aesKey : Xmlsec.Key.t;
  rsaPublicKeyFile : string;
  rsaPrivateKeyName : string;
}

let namespaces =
  [
    (* Namespaces.dba; *)
    Namespaces.ds;
    Namespaces.odrld;
    Namespaces.odrlx;
    Namespaces.xe;
    Namespaces.xsi
  ]

let rec apply l x = match l with 
  | [] -> x
  | f::fs -> f (apply fs x)

(*
let cleanStr str =
  let len = String.length str in
  let rec f start =
    try
      begin
        let pos = String.index_from str start '\n' in
        let s1 = String.sub str start (pos - start) in
        let s2 = f (pos + 1) in
        s1 ^ s2
      end
    with Not_found -> String.sub str start (len - start)
  in f 0

let rec cleanCipherValue = function
  | Libxml.Leaf ((el,[]),str) when el=xe_CipherValue ->
    Libxml.Leaf ((el,[]), (cleanStr str) )
  | Libxml.Leaf _ as leaf -> leaf
  | Libxml.Node (tag,nodelist) ->
    Libxml.Node (tag,List.map cleanCipherValue nodelist)
*)

let prepareKeyManager rsaPublicKeyFile =
  let rsaPublicKey = Xmlsec.App.cryptoAppKeyLoad rsaPublicKeyFile Xmlsec.Key.DERFormat in
  Xmlsec.Key.setName rsaPublicKey rsaPublicKeyFile;
  let keyManager = Xmlsec.KeyManager.create() in
  if ((Xmlsec.KeyManager.init keyManager)<0) then begin
    failwith "Could not initialize key manager"
  end;
  if ((Xmlsec.KeyManager.adoptKey keyManager rsaPublicKey)<0) then begin
    failwith "key manager could not adopt RSA public key";
  end;
  keyManager

let prepareEncryptedKey aesKey keyManager encryptionKeyName =
  let fantomDoc = Libxml.xmlNewDoc "1.0" in
  let fantomNode = Libxml.xmlNewNode "fantom" None None in
  Libxml.xmlDocSetRootElement fantomDoc fantomNode;    
  let td =
  {
    Xmlsec.Templates.td_document = Some fantomDoc;
    Xmlsec.Templates.td_encMethodId = Xmlsec.Transform.AES128CBC;
    Xmlsec.Templates.td_id = None;
    Xmlsec.Templates.td_type = Some "http://www.w3.org/2001/04/xmlenc#Element";
    Xmlsec.Templates.td_mimeType = None;
    Xmlsec.Templates.td_encoding = None
  }
  in
  let template = Xmlsec.Templates.encDataCreate td in
  ignore (Xmlsec.Templates.encDataEnsureCipherValue template);
  let keyInfoNode = Xmlsec.Templates.encDataEnsureKeyInfo template None in
  let encryptedKeyNode =
    Xmlsec.Templates.keyInfoAddEncryptedKey
      keyInfoNode
      {
        Xmlsec.Templates.ekd_encMethodId = Xmlsec.Transform.RSAPKCS1;
        Xmlsec.Templates.ekd_id = None;
        Xmlsec.Templates.ekd_type = None;
        Xmlsec.Templates.ekd_recipient = None
      }
  in
  let xe = Libxml.xmlSearchNsByHref fantomDoc template (Namespaces.uri Namespaces.xe) in
  ignore (Libxml.xmlNewChild encryptedKeyNode (Some xe) "CarriedKeyName" (Some "aeskey"));
  ignore (Xmlsec.Templates.encDataEnsureCipherValue encryptedKeyNode);
  let keyInfoNode2 = Xmlsec.Templates.encDataEnsureKeyInfo encryptedKeyNode None in
  ignore (Xmlsec.Templates.keyInfoAddKeyName keyInfoNode2 encryptionKeyName);
  let encryptionContext =
    Xmlsec.Xmlenc.encCtxCreate_with_key (Some keyManager) aesKey
  in
  let res = Xmlsec.Xmlenc.encCtxXmlEncrypt
    encryptionContext
    template
    fantomNode
  in    
  if res<0 then begin
    failwith "Could not encrypt encryption key"
  end;
  let p (el, _) = el=xe_EncryptedKey in
  let q = function
    | Libxml.Node ((el, []),_) when el=ds_KeyInfo -> true
    | _ -> false 
  in let rn = Libxml.openNode (Libxml.findNode p template) in
  let functions =
    [
(*
      cleanCipherValue;
*)
      Libxml.simplify;
      Libxml.clean;
      Libxml.remove q
    ]
  in apply functions rn

let encryptRights keyManager encryptionKeyName rights =
  let fantomDoc = Libxml.xmlNewDoc "1.0" in
  Libxml.xmlDocSetRootElement fantomDoc rights;    
  let td =
  {
    Xmlsec.Templates.td_document = Some fantomDoc;
    Xmlsec.Templates.td_encMethodId = Xmlsec.Transform.AES128CBC;
    Xmlsec.Templates.td_id = None;
    Xmlsec.Templates.td_type = Some "http://www.w3.org/2001/04/xmlenc#Element";
    Xmlsec.Templates.td_mimeType = None;
    Xmlsec.Templates.td_encoding = None
  }
  in
  let template = Xmlsec.Templates.encDataCreate td in
  ignore (Xmlsec.Templates.encDataEnsureCipherValue template);
  let keyInfoNode = Xmlsec.Templates.encDataEnsureKeyInfo template None in
  let encryptedKeyNode =
    Xmlsec.Templates.keyInfoAddEncryptedKey
      keyInfoNode
      {
        Xmlsec.Templates.ekd_encMethodId = Xmlsec.Transform.RSAPKCS1;
        Xmlsec.Templates.ekd_id = None;
        Xmlsec.Templates.ekd_type = None;
        Xmlsec.Templates.ekd_recipient = None
      }
  in
  ignore (Xmlsec.Templates.encDataEnsureCipherValue encryptedKeyNode);
  let keyInfoNode2 = Xmlsec.Templates.encDataEnsureKeyInfo encryptedKeyNode None in
  ignore (Xmlsec.Templates.keyInfoAddKeyName keyInfoNode2 encryptionKeyName);
  let aesKey = Xmlsec.Key.generate None 128 Xmlsec.Key.keyDataTypeSession in
  let encryptionContext =
    Xmlsec.Xmlenc.encCtxCreate_with_key (Some keyManager) aesKey
  in
  let res = Xmlsec.Xmlenc.encCtxXmlEncrypt
    encryptionContext
    template
    rights  in    
  if res<0 then begin
    failwith "Could not encrypt encryption key"
  end;
  let q = function
    | Libxml.Node ((el,[]),_) when el=ds_KeyInfo -> true
    | Libxml.Leaf ((el,[]),_) when el=ds_KeyInfo -> true
    | _ -> false 
  in let rn = Libxml.openNode template in
  let functions =
    [
(*
      cleanCipherValue;
*)
      Libxml.simplify;
      Libxml.clean;
    ]
  in let simplified = apply functions rn in
  let p' = function
    | Libxml.Node ((el ,_),_) when el=xe_EncryptedKey -> true
    | _ -> false
  in
  let (encryptedKey, encryptedData) = Libxml.findAndRemove p' simplified in
  let encryptedKey' = Libxml.remove q encryptedKey in
  let encryptedData' = Libxml.remove q encryptedData in
  let tag = (("","EncryptedRights"),[]) in
  Libxml.Node (tag, [encryptedKey'; encryptedData'])

let prepareRights bookIdentifier =
  let rightsDocument = Libxml.xmlNewDoc "1.0" in
  let rightsNode = Libxml.xmlNewNode "rights" (Some rightsDocument) None in
  Libxml.xmlDocSetRootElement rightsDocument rightsNode;      
  let odrld = Libxml.xmlNewNs rightsNode Namespaces.odrld in
  let odrlx = Libxml.xmlNewNs rightsNode Namespaces.odrlx in
  Libxml.xmlSetNs rightsNode odrlx;
  let agreementNode = Libxml.xmlNewChild rightsNode (Some odrlx) "agreement" None in
  let assetNode = Libxml.xmlNewChild agreementNode (Some odrlx) "asset" None in
  let contextNode = Libxml.xmlNewChild assetNode (Some odrlx) "context" None in
  let _ = Libxml.xmlNewChild contextNode (Some odrld) "uid" (Some bookIdentifier) in  
  let permissionNode = Libxml.xmlNewChild agreementNode (Some odrlx) "permission" None in
  let _ = Libxml.xmlNewChild permissionNode (Some odrlx) "play" None in
  rightsNode

let save fileName ao =
  let oc = open_out fileName in
  let o = Xml.make_output ~nl:true (`Channel oc) in
  let outputNode n =
    let rec f = function
      | Libxml.Leaf ((("","text"),[]),str) -> Xml.output o (`Data str); 
      | Libxml.Leaf (tag, str) ->
        Xml.output_text_element o tag str
      | Libxml.Node (tag,[]) -> Xml.output_empty_element o tag
      | Libxml.Node (tag, l) ->
        Xml.output_start_tag o tag;
        List.iter f l;
        Xml.output_end_tag o 
    in f n
  in
  let outputIssuerElement () =
    let tag = dba_Issuer, [dba_uid,ao.issuerIdentifier] in
    Xml.output_text_element o tag ao.issuerName
  in
  let outputBookElement () =
    let tag = dba_Book, [dba_uid, ao.bookIdentifier] in
    Xml.output_empty_element o tag 
  in
  let outputRights rights = outputNode (Libxml.simplify (Libxml.openNode rights))
  in
  let outputEncryptedRights keyManager encryptionKeyName rights =
    let encryptedRightsNode = encryptRights keyManager encryptionKeyName rights in
    outputNode encryptedRightsNode;
  in
  let outputContentKey keyManager encryptionKeyName =
    Xml.output_start_tag o (dba_ContentKey, [dba_media, "text"]);
    let encryptedKeyNode = prepareEncryptedKey ao.aesKey keyManager encryptionKeyName in
    outputNode encryptedKeyNode;    
    Xml.output_end_tag o (* </ContentKey> *)
  in
  let outputKeysElement encryptionKeyName rights =
    let keyManager = prepareKeyManager encryptionKeyName in
    Xml.output_start_tag o (dba_Keys, []);
    Xml.output_start_tag o (ds_KeyInfo, []);
    Xml.output_text_element o (ds_KeyName, []) ao.rsaPrivateKeyName;
    Xml.output_end_tag o; (* </ds:KeyInfo> *)
    outputContentKey keyManager encryptionKeyName;
    outputEncryptedRights keyManager encryptionKeyName rights;
    Xml.output_end_tag o; (* </Keys> *)
  in
  Xml.output o (`Dtd None);
  let rootAttributes =
    (
      Namespaces.default_namespace_attribute Namespaces.dba ::
      List.map Namespaces.declaration_attribute namespaces
    )
    @ [("","xsi:schemaLocation"),"http://www.daisy.org/DRM/2005/BookAuthorization AuthObj.xsd"]
  in
  let rights = prepareRights ao.bookIdentifier in
  Xml.output_start_tag o (dba_BookAuthorization, rootAttributes);
  outputIssuerElement ();
  outputBookElement ();
  outputRights rights;
  outputKeysElement ao.rsaPublicKeyFile rights;
  Xml.output_end_tag o; (* </BookAuthorization> *)
  close_out oc

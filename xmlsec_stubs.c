/*
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
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <xmlsec/xmlsec.h>
#include <xmlsec/xmldsig.h>
#include <xmlsec/xmlenc.h>
#include <xmlsec/xmltree.h>
#include <xmlsec/templates.h>
#include <xmlsec/crypto.h>
#include <xmlsec/keys.h>

#define CAML_NAME_SPACE /* Don't import old names */
#include <caml/mlvalues.h> /* definition of the value type, and conversion macros */
#include <caml/memory.h> /* miscellaneous memory-related functions and macros (for GC interface, in-place modification of structures, etc). */
#include <caml/alloc.h> /* allocation functions (to create structured Caml objects) */
#include <caml/fail.h> /* functions for raising exceptions */
#include <caml/callback.h>
#include <caml/custom.h>

#include "libxml.h"

/* Functions declared in keys.h: Key module in Caml */

static struct custom_operations xmlsec_key_ops = {
  "fr.braillenet.xmlsec.key",  
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* Accessing the xmlSecKeyPtr part of a Caml custom block */
#define Key_val(v) (*((xmlSecKeyPtr *) Data_custom_val(v)))

/* Allocating a Caml custom block to hold the given xmlSecKeyPtr */
static value alloc_key(xmlSecKeyPtr k)
{
  value v = caml_alloc_custom(&xmlsec_key_ops, sizeof(xmlSecKeyPtr), 0, 1);
  Key_val(v) = k;
  return v;
}

CAMLprim value xmlsecml_xmlSecKeyGenerate(value camlId, value camlSize, value camlType)
{
  CAMLparam3(camlId, camlSize, camlType);
  xmlSecKeyDataId id;
  xmlSecSize size;
  xmlSecKeyDataType type;
  xmlSecKeyPtr key = NULL;
  assert ( Is_long(camlId) );
  id = xmlSecKeyDataAesId;
  size = Int_val(camlSize);
  type = Int_val(camlType);
  key = xmlSecKeyGenerate(id, size, type);
  assert(key != NULL);
  CAMLreturn(alloc_key(key));
}

CAMLprim value xmlsecml_xmlSecKeySetName(value camlKey, value camlName)
{
  CAMLparam2(camlKey, camlName);
  int res;
  xmlSecKeyPtr key = Key_val(camlKey);
  unsigned char *name = (unsigned char *) String_val(camlName);
  res = xmlSecKeySetName(key, name);
  CAMLreturn(Val_int(res));
}

CAMLprim value xmlsecml_xmlSecKeyReadBinaryFile(value camlKeyDataId, value camlFileName)
{
  CAMLparam2(camlKeyDataId, camlFileName);
  xmlSecKeyDataId keyDataId = xmlSecKeyDataAesId;
  char *filename = String_val(camlFileName);
  xmlSecKeyPtr key = xmlSecKeyReadBinaryFile(keyDataId, filename);
  assert(key!=NULL);
  CAMLreturn(alloc_key(key));
}

/* Functions declared in keysmngr.h.h: KeyManager module in Caml */

static struct custom_operations xmlsec_keymngr_ops = {
  "fr.braillenet.xmlsec.keymngr",  
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* Accessing the xmlSecKeysMngrPtr part of a Caml custom block */
#define Keymngr_val(v) (*((xmlSecKeysMngrPtr *) Data_custom_val(v)))

/* Allocating a Caml custom block to hold the given xmlSecKeysMngrPtr */
static value alloc_keymngr(xmlSecKeysMngrPtr km)
{
  value v = caml_alloc_custom(&xmlsec_keymngr_ops, sizeof(xmlSecKeyPtr), 0, 1);
  Keymngr_val(v) = km;
  return v;
}

CAMLprim value xmlsecml_xmlSecKeysMngrCreate(value unit)
{
  CAMLparam1(unit);
  xmlSecKeysMngrPtr km;
  km = xmlSecKeysMngrCreate();
  assert(km!=NULL);
  CAMLreturn(alloc_keymngr(km));
}

CAMLprim value xmlsecml_xmlSecCryptoAppDefaultKeysMngrInit(value camlKeyManager)
{
  CAMLparam1(camlKeyManager);
  int res;
  xmlSecKeysMngrPtr keyManager = Keymngr_val(camlKeyManager);
  res = xmlSecCryptoAppDefaultKeysMngrInit(keyManager);  
  CAMLreturn(Val_int(res));
}

CAMLprim value xmlsecml_xmlSecCryptoAppDefaultKeysMngrAdoptKey(value camlKeyManager, value camlKey)
{
  CAMLparam2(camlKeyManager, camlKey);
  int res;
  xmlSecKeysMngrPtr keyManager = Keymngr_val(camlKeyManager);
  xmlSecKeyPtr key = Key_val(camlKey);
  res = xmlSecCryptoAppDefaultKeysMngrAdoptKey(keyManager, key);
  CAMLreturn(Val_int(res));
}

CAMLprim value xmlsecml_xmlSecKeysMngrDestroy(value camlKeyManager)
{
  CAMLparam1(camlKeyManager);
  xmlSecKeysMngrDestroy(Keymngr_val(camlKeyManager));  
  CAMLreturn(Val_unit);
}

/* Functions declared in templates.h: Templates module in Caml */

CAMLprim value xmlsecml_xmlSecTmplEncDataCreate(value camlData)
{
  CAMLparam1(camlData);
  xmlDocPtr document = NULL;
  xmlSecTransformId encMethodId;
  const xmlChar *id = NULL; 
  const xmlChar *type = NULL;
  const xmlChar *mimeType;
  const xmlChar *encoding;
  xmlNodePtr template = NULL;
  if (Is_long( Field(camlData, 0) ))
  {
    document = NULL;
  } else {
    document = Doc_val ( Field( Field( camlData, 0), 0) );
  }
  switch (Int_val(Field(camlData, 1)))
  {
    case 0: encMethodId = xmlSecTransformAes128CbcId; break;
    case 1: encMethodId = xmlSecTransformRsaPkcs1Id; break;
    default: {
      fprintf(stderr,"Unknown value for encryption method in xmlsecml_xmlSecTmplEncDataCreate\n");
      exit(1);
    }
  };
  id = (xmlChar *) Stringoption_val( Field(camlData, 2) );
  type = (xmlChar *) Stringoption_val( Field(camlData, 3));
  mimeType = (xmlChar *) Stringoption_val( Field(camlData, 4));
  encoding = (xmlChar *) Stringoption_val( Field(camlData, 5));
  template = xmlSecTmplEncDataCreate(
    document,
    encMethodId,
    id,
    type,
    mimeType,
    encoding
  );
  assert(template != NULL);
  CAMLreturn(alloc_node(template));
}

CAMLprim value xmlsecml_xmlSecTmplEncDataEnsureCipherValue(value camlTemplate)
{
  CAMLparam1(camlTemplate);
  xmlNodePtr template = Node_val(camlTemplate);
  xmlNodePtr cipherValueNode = xmlSecTmplEncDataEnsureCipherValue(template); 
  assert(cipherValueNode != NULL);
  CAMLreturn(alloc_node(cipherValueNode));
}

CAMLprim value xmlsecml_xmlSecTmplEncDataEnsureKeyInfo(value camlTemplate, value camlId)
{
  CAMLparam2(camlTemplate, camlId);
  xmlNodePtr template;
  xmlChar *id;
  template = Node_val(camlTemplate);
  id = (xmlChar *) Stringoption_val( camlId);
  xmlNodePtr keyInfoNode = xmlSecTmplEncDataEnsureKeyInfo(template, id); 
  assert(keyInfoNode != NULL);
  CAMLreturn(alloc_node(keyInfoNode));
}

CAMLprim value xmlsecml_xmlSecTmplKeyInfoAddEncryptedKey(value camlNode, value camlData)
{
  CAMLparam2(camlNode, camlData);
  xmlNodePtr keyInfoNode = Node_val(camlNode);
  xmlSecTransformId encMethodId;
  const xmlChar *id = NULL;
  const xmlChar *type = NULL;
  const xmlChar *recipient = NULL;
  xmlNodePtr encryptedKeyNode = NULL;
  switch (Int_val(Field(camlData, 0)))
  {
    case 0: encMethodId = xmlSecTransformAes128CbcId; break;
    case 1: encMethodId = xmlSecTransformRsaPkcs1Id; break;
    default: {
      fprintf(stderr,"Unknown value for encryption method in xmlsecml_xmlSecTmplEncDataCreate\n");
      exit(1);
    }
  };
  id = (xmlChar *) Stringoption_val(Field(camlData, 1));
  type = (xmlChar *) Stringoption_val(Field(camlData, 2));
  recipient = (xmlChar *) Stringoption_val(Field(camlData, 3));
  encryptedKeyNode = xmlSecTmplKeyInfoAddEncryptedKey
  (
    keyInfoNode,
    encMethodId,
    id,
    type,
    recipient
  );
  assert(encryptedKeyNode != NULL);
  CAMLreturn(alloc_node(encryptedKeyNode));
}

CAMLprim value xmlsecml_xmlSecTmplKeyInfoAddKeyName(value camlKeyInfoNode, value camlKeyName)
{
  CAMLparam2(camlKeyInfoNode, camlKeyName);  
  xmlNodePtr keyInfoNode = Node_val(camlKeyInfoNode);
  xmlChar *keyName = (xmlChar *) String_val(camlKeyName); 
  xmlNodePtr keyNameNode = xmlSecTmplKeyInfoAddKeyName(keyInfoNode, keyName);
  assert(keyNameNode != NULL);
  CAMLreturn(alloc_node(keyNameNode));
}

/* Functions declared in xmlenc.h: Xmlenc module in Caml */

static struct custom_operations xmlsec_encCtx_ops = {
  "fr.braillenet.xmlsec.encCtx",  
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* Accessing the xmlSecEncCtxPtr part of a Caml custom block */
#define EncCtx_val(v) (*((xmlSecEncCtxPtr *) Data_custom_val(v)))

/* Allocating a Caml custom block to hold the given xmlSecEncCtxPtr */
static value alloc_encCtx(xmlSecEncCtxPtr e)
{
  value v = caml_alloc_custom(&xmlsec_encCtx_ops, sizeof(xmlSecEncCtxPtr), 0, 1);
  EncCtx_val(v) = e;
  return v;
}

CAMLprim value xmlsecml_xmlEncCtxCreate_with_key(value camlKeyManager, value camlKey)
{
  CAMLparam2(camlKeyManager, camlKey);
  xmlSecKeysMngrPtr keyManager = Is_long(camlKeyManager) ? NULL : Keymngr_val(Field(camlKeyManager, 0));
  xmlSecEncCtxPtr encCtx = xmlSecEncCtxCreate(keyManager);
  assert(encCtx != NULL);
  encCtx->encKey = Key_val(camlKey);
  CAMLreturn(alloc_encCtx(encCtx));
}

CAMLprim value xmlsecml_setCarriedKeyName(value camlEncCtx, value camlCarriedKeyName)
{
  CAMLparam2(camlEncCtx, camlCarriedKeyName);
  xmlSecEncCtxPtr encCtx = EncCtx_val(camlEncCtx);
  xmlChar *carriedKeyName = (xmlChar *) String_val(camlCarriedKeyName);
  encCtx->carriedKeyName = carriedKeyName;
  CAMLreturn(Val_unit);
}

CAMLprim value xmlsecml_encCtxXmlEncrypt(value camlEncCtx, value camlTemplate, value camlNode)
{
  CAMLparam3(camlEncCtx, camlTemplate, camlNode);
  int res;
  xmlSecEncCtxPtr encCtx = EncCtx_val(camlEncCtx);
  xmlNodePtr template = Node_val(camlTemplate);
  xmlNodePtr node = Node_val(camlNode);
  res = xmlSecEncCtxXmlEncrypt(encCtx, template, node);
  CAMLreturn(Val_int(res));
}

/* Functions declared in xmlsec.h and app.h: App module in Caml */

CAMLprim value xmlsecml_xmlSecInit(value unit)
{
  CAMLparam1(unit);
  int ret = xmlSecInit();
  CAMLreturn(Val_int(ret));
}

CAMLprim value xmlsecml_xmlSecCryptoAppInit(value camlConfig)
{
  CAMLparam1(camlConfig);
  char *config;
  int ret;
  if (Is_long(camlConfig)) config = NULL;
  else config = String_val(Field(camlConfig,0));
#ifdef XMLSEC_CRYPTO_DYNAMIC_LOADING
  xmlSecCryptoDLLoadLibrary(BAD_CAST XMLSEC_CRYPTO);
#endif
  ret = xmlSecCryptoAppInit(config);
  CAMLreturn(Val_int(ret));
}

CAMLprim value xmlsecml_xmlSecCryptoInit(value unit)
{
  CAMLparam1(unit);
  int ret = xmlSecCryptoInit();
  CAMLreturn(Val_int(ret));
}

CAMLprim value xmlsecml_xmlSecCryptoShutdown(value unit)
{
  CAMLparam1(unit);
  xmlSecCryptoShutdown();
  CAMLreturn(Val_unit);
}

CAMLprim value xmlsecml_xmlSecCryptoAppShutdown(value unit)
{
  CAMLparam1(unit);
  xmlSecCryptoAppShutdown();
  CAMLreturn(Val_unit);
}

CAMLprim value xmlsecml_xmlSecShutdown(value unit)
{
  CAMLparam1(unit);
  xmlSecShutdown();
  CAMLreturn(Val_unit);
}

CAMLprim value xmlsecml_xmlSecCryptoAppKeyLoad(value camlFilename, value camlFormat)
{
  CAMLparam2(camlFilename, camlFormat);
  const char *filename = String_val(camlFilename);
  xmlSecKeyDataFormat format = Int_val(camlFormat);
  xmlSecKeyPtr key =
    xmlSecCryptoAppKeyLoad(filename, format, NULL, NULL, NULL);
  assert(key != NULL);
  CAMLreturn(alloc_key(key));
}

/* Other functions which are not stub cod */

CAMLprim value encryptFile(value camlKey, value camlSource, value camlDestination)
{
  CAMLparam3(camlKey, camlSource, camlDestination);
  char *source = String_val(camlSource);
  char *destination = String_val(camlDestination);
  xmlDocPtr doc = NULL;
  xmlNodePtr encDataNode = NULL;
  xmlSecEncCtxPtr encCtx = NULL;
  FILE *f;

  doc = xmlParseFile(source);
  if ((doc == NULL) || (xmlDocGetRootElement(doc) == NULL))
  {
    fprintf(stderr, "Error: unable to parse file \"%s\"\n", source);
    exit(1);
  }
  encDataNode = xmlSecTmplEncDataCreate(doc, xmlSecTransformAes128CbcId, NULL, xmlSecTypeEncElement, NULL, NULL);
  if (encDataNode == NULL)
  {
    fprintf(stderr, "Error: failed to create encryption template\n");
    xmlFreeDoc(doc);
    exit(1);
  }
  if (xmlSecTmplEncDataEnsureCipherValue(encDataNode) == NULL)
  {
    fprintf(stderr, "Error: failed to add CipherValue node\n");
    xmlFreeDoc(doc);
    exit(1);
  }
  encCtx = xmlSecEncCtxCreate(NULL);
  if (encCtx == NULL)
  {
    fprintf(stderr,"Error: failed to create encryption context\n");
    xmlFreeDoc(doc);
    exit(1);
  }
  encCtx->encKey = Key_val(camlKey);
  if (xmlSecEncCtxXmlEncrypt(encCtx, encDataNode, xmlDocGetRootElement(doc)) < 0)
  {
    fprintf(stderr,"Error: encryption failed\n");
    exit(1);
  }
  f = fopen(destination, "w");
  if (f==NULL)
  {
    perror("fopen");
    exit(1);
  }
  xmlDocDump(f, doc);
  fclose(f);
  encCtx-> encKey = NULL;
  xmlSecEncCtxDestroy(encCtx);
  xmlFree(doc);
  CAMLreturn(Val_unit);    
}

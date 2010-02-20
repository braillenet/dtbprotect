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

#include <libxml/tree.h>

#define CAML_NAME_SPACE /* Don't import old names */
#include <caml/mlvalues.h> /* definition of the value type, and conversion macros */
#include <caml/memory.h> /* miscellaneous memory-related functions and macros (for GC interface, in-place modification of structures, etc). */
#include <caml/alloc.h> /* allocation functions (to create structured Caml objects) */
#include <caml/fail.h> /* functions for raising exceptions */
#include <caml/callback.h>
#include <caml/custom.h>

#include "libxml.h"

caml_custom_operations libxml_doc_ops = {
  "fr.braillenet.libxml.doc",  
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* Allocating a Caml custom block to hold the given xmlDocPtr */
value alloc_doc(xmlDocPtr d)
{
  value v = caml_alloc_custom(&libxml_doc_ops, sizeof(xmlDocPtr), 0, 1);
  Doc_val(v) = d;
  return v;
}

caml_custom_operations libxml_ns_ops = {
  "fr.braillenet.libxml.ns",  
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* Allocating a Caml custom block to hold the given xmlNsPtr */
value alloc_ns(xmlNsPtr ns)
{
  value v = caml_alloc_custom(&libxml_ns_ops, sizeof(xmlNsPtr), 0, 1);
  Ns_val(v) = ns;
  return v;
}

caml_custom_operations libxml_node_ops = {
  "fr.braillenet.libxml.node",  
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* Allocating a Caml custom block to hold the given xmlNodePtr */
value alloc_node(xmlNodePtr n)
{
  value v = caml_alloc_custom(&libxml_node_ops, sizeof(xmlDocPtr), 0, 1);
  Node_val(v) = n;
  return v;
}

CAMLprim value libxmlml_xmlNewDoc(value camlVersion)
{
  CAMLparam1(camlVersion);
  const xmlChar *version = (xmlChar *) String_val(camlVersion);
  xmlDocPtr doc = xmlNewDoc(version);
  assert(doc != NULL);
  CAMLreturn(alloc_doc(doc));  
}

CAMLprim value libxmlml_xmlNewNode(value camlName, value camlDocument, value camlNamespace)
{
  CAMLparam3(camlName, camlDocument, camlNamespace);
  const xmlChar *name = (xmlChar *) String_val(camlName); 
  xmlDocPtr document = Is_long(camlDocument) ? NULL : Doc_val(Field(camlDocument,0));
  xmlNsPtr namespace = Is_long(camlNamespace) ? NULL : Ns_val(Field(camlNamespace,0));
  xmlNodePtr node = xmlNewDocNode(document, namespace, name, NULL);
  assert(node != NULL);
  CAMLreturn(alloc_node(node));  
}

CAMLprim value libxmlml_xmlNewNs(value camlNode, value camlNamespace)
{
  CAMLparam2(camlNode, camlNamespace);
  xmlNodePtr node = Node_val(camlNode);
  xmlChar *href = (xmlChar *) String_val(Field(camlNamespace, 0));
  xmlChar *prefix = (xmlChar *) String_val(Field(camlNamespace, 1));
  xmlNsPtr namespace = xmlNewNs(node, href, prefix);
  assert(namespace!=NULL);
  CAMLreturn(alloc_ns(namespace));
}

CAMLprim value libxmlml_xmlSetNs(value camlNode, value camlNamespace)
{
  CAMLparam2(camlNode, camlNamespace);
  xmlNodePtr node = Node_val(camlNode);
  xmlNsPtr namespace = Ns_val(camlNamespace);
  xmlSetNs(node, namespace);
  CAMLreturn(Val_unit);
}

CAMLprim value libxmlml_xmlNewProp(value camlNode, value camlName, value camlValue)
{
  CAMLparam3(camlNode, camlName, camlValue);
  xmlNodePtr node = Node_val(camlNode);
  const xmlChar *name = ((xmlChar *) String_val(camlName));
  const xmlChar *val = ((xmlChar *) String_val(camlValue));
  xmlAttrPtr a = xmlNewProp(node, name, val);  
  assert(a != NULL);
  CAMLreturn(Val_unit);  
}

CAMLprim value libxmlml_xmlNewChild(value camlParent, value camlNamespace, value camlName, value camlContent)
{
  CAMLparam4(camlParent, camlNamespace, camlName, camlContent);
  xmlChar *name = NULL, *content = NULL;
    xmlNodePtr parent = NULL, child = NULL;
  xmlNsPtr namespace = NULL;
  namespace = Is_long(camlNamespace) ? NULL : Ns_val(Field(camlNamespace,0));
  parent = Node_val(camlParent);
  name = ((xmlChar *) String_val(camlName)); 
  content = (xmlChar *) Stringoption_val(camlContent);
  child = xmlNewChild(parent, namespace, name, content);
  assert(child != NULL);
  CAMLreturn(alloc_node(child));  
}

CAMLprim value libxmlml_xmlDocSetRootElement(value camlDocument, value camlRoot)
{
  CAMLparam2(camlDocument, camlRoot);
  xmlDocPtr document = Doc_val(camlDocument);
  xmlNodePtr root = Node_val(camlRoot);
  xmlDocSetRootElement(document, root);
  CAMLreturn(Val_unit);
}

CAMLprim value libxmlml_xmlSearchNsByHref(value camlDocument, value camlNode, value camlHref)
{
  CAMLparam3(camlDocument, camlNode, camlHref);
  xmlDocPtr document = Doc_val(camlDocument);
  xmlNodePtr node = Node_val(camlNode);  
  xmlChar *href = (xmlChar *) String_val(camlHref);
  xmlNsPtr namespace = xmlSearchNsByHref(document, node, href);
  assert(namespace!=NULL);
  CAMLreturn(alloc_ns(namespace));
}

static value makeName(xmlNodePtr node)
{
  CAMLlocal1(v);
  v = caml_alloc_tuple(2);
  if ((node->type==XML_ELEMENT_NODE) && (node->ns != NULL) && (node->ns->href != NULL) && (*(node->ns->href)))
  {
    Store_field(v, 0, caml_copy_string((char *) node->ns->href));
  } else {
    Store_field(v, 0, caml_copy_string(""));
  }
  Store_field(v, 1, caml_copy_string((char *) node->name));
  return v;
}

static value makeAttribute(xmlAttrPtr attr)
{
  CAMLlocal1(v);
  char *s = NULL;
  if ((attr->children!=NULL) && (attr->children->content!=NULL))
  {
    s = (char *) attr->children->content;  
  }
  v = caml_alloc_tuple(2);
  Store_field(v, 0, makeName((xmlNodePtr) attr));
  Store_field(v, 1, caml_copy_string(s));
  return v;
}

static value makeElement(xmlNodePtr node)
{
  value res = caml_alloc_tuple(2);
  Store_field(res, 0, makeName(node));
  if (node->properties==NULL) {
    Store_field(res, 1, Val_int(0)); 
  } else {
    xmlAttrPtr p = node->properties;
    value q = res;
    int field = 1;
    while (p!=NULL)
    {
      value tmp = caml_alloc(2, 0);
      Store_field(tmp, 0, makeAttribute(p));
      Store_field(tmp, 1, Val_int(0));
      Store_field(q, field, tmp);
      field = 0;
      q = tmp;
      p = p->next;    
    }
  }
  return res;  
}

CAMLprim value libxmlml_openNode(value camlNode)
{
  CAMLparam1(camlNode);
  CAMLlocal1(rawNode);
  xmlNodePtr node;
  node = Node_val(camlNode);
  assert(node!=NULL); 
  assert(node->type == XML_ELEMENT_NODE || node->type == XML_TEXT_NODE);
  if (node->type==XML_TEXT_NODE)
  {
    rawNode = caml_alloc(2, 0);
    Store_field(rawNode, 0, makeElement(node));
    Store_field(rawNode, 1, caml_copy_string((char *) node->content));
    CAMLreturn(rawNode);
  }
  rawNode = caml_alloc(2, 1);
  Store_field(rawNode, 0, makeElement(node));
  if (node->children == NULL) {
    Store_field(rawNode, 1, Val_int(0));
  } else {
    xmlNodePtr p = node->children;
    value v = caml_alloc(2,0);
    Store_field(v, 0, alloc_node(p));
    Store_field(rawNode, 1, v);
    while (p->next != NULL)
    {
      value tmp;
      p = p->next;
      tmp = caml_alloc(2, 0);
      Store_field(tmp, 0, alloc_node(p));
      Store_field(v, 1, tmp);
      v = tmp;
    }
    Store_field(v, 1, Val_int(0) ); 
  }
  CAMLreturn(rawNode);
}

CAMLprim value libxmlml_init(value unit)
{
  CAMLparam1(unit);
  xmlInitParser();
  LIBXML_TEST_VERSION
  xmlLoadExtDtdDefaultValue = XML_DETECT_IDS | XML_COMPLETE_ATTRS;
  xmlSubstituteEntitiesDefault(1);
  #ifndef XMLSEC_NO_XSLT
  xmlIndentTreeOutput = 1;
  #endif /* XMLSEC_NO_XSLT */
  CAMLreturn(Val_unit);
}

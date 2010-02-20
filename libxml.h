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

#define CAML_NAME_SPACE

#include <caml/mlvalues.h>

typedef struct custom_operations caml_custom_operations; 
extern caml_custom_operations libxml_doc_ops;
extern caml_custom_operations libxml_sn_ops;

/* Accessing the xmlDocPtr part of a Caml custom block */
#define Doc_val(v) (*((xmlDocPtr *) Data_custom_val(v)))
/* Allocating a Caml custom block to hold the given xmlDocPtr */
extern value alloc_doc(xmlDocPtr d);

/* Accessing the xmlNsPtr part of a Caml custom block */
#define Ns_val(v) (*((xmlNsPtr *) Data_custom_val(v)))
/* Allocating a Caml custom block to hold the given xmlNsPtr */
extern value alloc_ns(xmlNsPtr d);

extern caml_custom_operations libxml_node_ops;

/* Accessing the xmlNodePtr part of a Caml custom block */
#define Node_val(v) (*((xmlNodePtr *) Data_custom_val(v)))

/* Allocating a Caml custom block to hold the given xmlNodePtr */
extern value alloc_node(xmlNodePtr n);

static char *Stringoption_val(value v)
{
  return Is_long(v) ? NULL : String_val(Field(v,0));
}

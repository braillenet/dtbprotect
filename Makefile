###############################################################################
# dtbprotect - A Digital Talking Book encryption program.
#
# Copyright (C) 2009-2010 by The dtbprotect developers (see AUTHORS file).
#
# dtbprotect comes with ABSOLUTELY NO WARRANTY.
#
# This is free software, placed under the terms of the
# GNU General Public License, as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any
# later version. Please see the file GPLV2 for details.
#
# Web Page: http://www.serveur-helene.org/
###############################################################################

SOURCES = \
  libxml_stubs.c xmlsec_stubs.c \
  xmlm.mli xmlm.ml \
  xml.mli xml.ml \
  namespaces.mli namespaces.ml \
  elements.mli elements.ml \
  dublinCore.mli dublinCore.ml \
  dtb.mli dtb.ml \
  libxml.mli libxml.ml \
  xmlsec.mli xmlsec.ml \
  package.mli package.ml \
  authorisationObject.mli authorisationObject.ml \
  main.ml

RESULT = dtbprotect
PACKS = unix
CFLAGS = -g -O0 -Wall -DXMLSEC_NO_SIZE_T -DXMLSEC_CRYPTO_OPENSSL -I/usr/include/libxml2 -I/usr/include/xmlsec1 $(shell pkg-config --cflags xmlsec1 | sed "s/\(\\\\\".*\\\\\"\)/\'\1\'/g")
CLIBS = xmlsec1-openssl xmlsec1 ssl crypto xslt xml2

include OCamlMakefile

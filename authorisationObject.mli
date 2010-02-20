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
  bookIdentifier : string;
  issuerName : string;
  issuerIdentifier : string;
  aesKey : Xmlsec.Key.t;
  rsaPublicKeyFile : string;
  rsaPrivateKeyName : string;
}

val save : string -> t -> unit

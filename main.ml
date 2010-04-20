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

open Dtb
open Package
open Filename

type options = {
  input : string;
  output : string;
  key : string;
  private_key_name : string;
  encrypt_ncx : bool;
  encrypt_smil : bool
}

let options_initializer = {
  input = "";
  output = "";
  key = "";
  private_key_name = "";
  encrypt_ncx = false;
  encrypt_smil = false
}

let abort msg =
  Printf.eprintf "%s\n" msg;
  exit 1

let err_missing_argument opt =
  let msg = "The " ^ opt ^ " option expects an argument"
  in abort msg

let err_unknown_option opt =
  abort ("Unknown option " ^ opt)

let err_not_spec x =
  let msg = "No " ^ x ^ " has been specified" in
  abort msg

let parse_command_line arguments =
  let rec f options = function
    | [] -> options
    | "--input"::rem ->
      begin match rem with
        | [] -> err_missing_argument "--input"
        | x::xs ->
          f { options with input = x } xs  
      end
    | "--output"::rem ->
      begin match rem with
        | [] -> err_missing_argument "--output"
        | x::xs ->
          f { options with output = x } xs  
      end
    | "--key"::rem ->
      begin match rem with
        | [] -> err_missing_argument "--key"
        | x::xs ->
          f { options with key = x } xs  
      end
    | "--private_key_name"::rem ->
      begin match rem with
        | [] -> err_missing_argument "--private_key_name"
        | x::xs ->
          f { options with private_key_name = x } xs  
      end

    | "--encrypt-ncx"::xs ->
      f { options with encrypt_ncx = true } xs
    | "--encrypt-smil"::xs ->
      f { options with encrypt_smil = true } xs
    | opt::_ -> err_unknown_option opt
  in f options_initializer arguments

let check options =
  if options.input="" then
    err_not_spec "input file"
  else if options.output="" then
    err_not_spec "output directory"
  else if options.key="" then
    err_not_spec "public key"
  else if options.private_key_name="" then
    err_not_spec "private key name"
  else ()

let cp src dst =
  let cmd = "cp " ^ src ^" " ^ dst in
  match Unix.system cmd with
    | Unix.WEXITED 0 -> ()
    | _ -> failwith
      ("An error occurred while copying " ^ src ^ " to " ^ dst)

let main options =
  check options;
  let aesKey = Xmlsec.Key.generate None 128 Xmlsec.Key.keyDataTypeSession in
  let input_directory = (Filename.dirname options.input) ^ "/" in
  let input_package = Package.load options.input in
  let authorisation = options.output ^ "book.ao" in
  let ao = {
    AuthorisationObject.bookIdentifier =
    begin
      try (DublinCore.content 
        (DublinCore.find DublinCore.Identifier input_package.dc)
      )
      with Not_found -> abort "Could not find identifier for input book"
    end;
    AuthorisationObject.issuerName = "Association BrailleNet";
    AuthorisationObject.issuerIdentifier = "daisy.fr.braillenet";
    AuthorisationObject.aesKey = aesKey;
    AuthorisationObject.rsaPublicKeyFile = options.key;
    AuthorisationObject.rsaPrivateKeyName = options.private_key_name
  } in  
  AuthorisationObject.save authorisation ao;
  let facade_manifest =
  [
    {
      Package.href = "./package.opf";
      Package.id = "opf";
      Package.mediaType = "text/xml"
    };
    {
      Package.href = "./facade.smil";
      Package.id = "smil";
      Package.mediaType = "application/smil"
    };
    {
      Package.href = "./facade.xml";
      Package.id = "xml";
      Package.mediaType = "application/x-dtbook+xml"
    }
  ]
  in
  let facade_ncx = {
    ncx_href = "facade.ncx";
    ncx_mediatype = "application/x-dtbncx+xml"
  } in
  let x0 = match input_package.x with
    | None -> Dtb.dtb_metadata_initializer
    | Some y -> y
  in
  let facade =
  {
    dtd = input_package.dtd;
    uniqueIdentifier = input_package.uniqueIdentifier;
    x = Some ({ x0 with 
      pdtb2_SpecVersion = (Some "2005-1");
      pdtb2_Package = (Some "package.ppf");
      pdtb2_Authorization = (Some "book.ao")
    });
    dc = input_package.dc;
    manifest = facade_manifest;
    ncx = facade_ncx;
    spine = ["smil"];
    tours = [];
    guide = []
  }
  in
  let protected_manifest =
    ref [{
      Package.href = "./book.ao";
      Package.id = "ao";
      Package.mediaType = "application/x-pdtbauth+xml";
    }]
  in
  let process_manifest_item i =
    let infile = input_directory ^ i.href in
    let outfile = options.output ^ i.href in
    match i.mediaType with
      | "application/smil" ->
        if options.encrypt_smil then begin
          Xmlsec.encryptFile aesKey infile outfile; 
          protected_manifest := 
            !protected_manifest @
            [{ i with mediaType = "application/x-pdtbsmil+xml" }]
        end else begin
          cp infile outfile;
          protected_manifest := !protected_manifest @ [i]
        end
      | "application/x-dtbresource+xml" ->
        begin
          cp infile outfile;
          protected_manifest := !protected_manifest @ [i]
        end
      | "application/x-dtbook+xml" ->
        Xmlsec.encryptFile aesKey infile outfile;
        protected_manifest := 
          !protected_manifest @
          [{ i with mediaType = "application/x-pdtbook+xml" }]
      | "text/xml" -> ()
      | s ->
        let msg = "Unknown media type " ^ s ^ ", href=" ^ i.href in
        abort msg
  in
  List.iter process_manifest_item input_package.manifest;
  let inf = input_directory ^ input_package.ncx.ncx_href in
  if options.encrypt_ncx then begin
    let outf = options.output ^ "book.pncx" in
    Xmlsec.encryptFile aesKey inf outf
  end else begin
    let outf = options.output ^ "book.ncx" in
    cp inf outf
  end;
  let protected_ncx = 
  if options.encrypt_ncx then
  {
    ncx_href = "book.pncx";
    ncx_mediatype = "application/x-pdtbook+xml"
  } else {
    ncx_href = "book.ncx";
    ncx_mediatype = "application/x-dtbncx+xml"
  }
  in 
  protected_manifest := !protected_manifest @
  ( { href = facade_ncx.ncx_href;
      id = "facade-ncx";
      mediaType = facade_ncx.ncx_mediatype
    } :: facade_manifest
  );  
  let protected_package =
  {
    dtd = input_package.dtd;
    uniqueIdentifier = input_package.uniqueIdentifier;
    x = input_package.x;
    dc = input_package.dc;
    manifest = !protected_manifest;
    ncx = protected_ncx;
    spine = input_package.spine;
    tours = input_package.tours;
    guide = input_package.guide    
  }
  in
  Package.save (options.output ^ "package.ppf") protected_package;
  Package.save (options.output ^ "package.opf") facade

let xmlsecInit () =
  let f code what =
    if code<0 then begin
      let s = ("Error " ^ (string_of_int code) ^ " while initializing " ^ what)
      in failwith s
    end else ()
  in
  f ( Xmlsec.App.init () ) "xmlsec";
  f ( Xmlsec.App.cryptoAppInit None ) "xmlsec crypto app";
  f ( Xmlsec.App.cryptoInit () ) "xmlsec crypto library"

let xmlsecShutdown () =
  Xmlsec.App.cryptoShutdown ();
  Xmlsec.App.cryptoAppShutdown();
  Xmlsec.App.shutdown()

let _ =
  Libxml.init();
  xmlsecInit ();
  let arguments = List.tl (Array.to_list Sys.argv) in
  let options = parse_command_line arguments in
  main options;
  xmlsecShutdown ()

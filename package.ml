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

(* Package manipulaiton module *)

open DublinCore
open Dtb

type manifestItem = {
  href : string;
  id : string;
  mediaType : string
}

type manifest = manifestItem list

type ncx = {
  ncx_href : string;
  ncx_mediatype : string
}

type tour = string

type guide = string list

type t = {
  dtd : string;
  uniqueIdentifier : string;
  dc : dc_metadata;
  x : dtb_metadata option;
  manifest : manifest;
  ncx : ncx;
  spine : string list;
  tours : tour list;
  guide : guide
}

let is_ncx i = i.id="ncx"

let extract_ncx l0 =
  let (l1, l2) = List.partition is_ncx l0 in
  match l1 with
    | [] -> failwith "The manifest contains no item with id=ncx"
    | [i] ->
      let ncx = { ncx_href = i.href; ncx_mediatype = i.mediaType } in
      l2, ncx
    | _::_::_ -> failwith "The manifest contains too many items with id=ncx"

let input_metadata i =
  match Xml.input_signal i with
    | `El_start (el, []) when el = Elements.oeb_metadata ->
      let dcmd = input_dc_metadata i in
      let xmd = input_dtb_metadata i in
      assert ((Xml.input_signal i) = `El_end);
      (dcmd, xmd)
    | _ as signal ->
      let str = Xml.string_of_signal signal in
      let (mdns, mdname) = Elements.oeb_metadata in
      let elstr = ("namespace=" ^ mdns ^" name=" ^ mdname) in
      failwith ("Unexpected signal " ^ str ^ ", expected elemennt " ^ elstr)

let input_item i = match Xml.peek i with
  | `El_start (el, a) when el = Elements.oeb_item ->
    ignore (Xml.input_signal i);
    assert ((Xml.input_signal i) = `El_end);
    let cmp = fun ((_,x),_) ((_,y),_) -> String.compare x y in
    let x =
    begin match List.sort cmp a with
      | [((_,"href"),href_);((_,"id"),id_);((_,"media-type"),mediatype_)] ->
      {
        href = href_;
        id = id_;
        mediaType = mediatype_; 
      }
      | _ -> failwith "item element has wrong list of attributes"
    end in Some x
  | _ -> None
 
let input_manifest i = match Xml.input_signal i with
  | `El_start (el, []) when el = Elements.oeb_manifest ->
    let l = Xml.input_list input_item i in
    assert ((Xml.input_signal i) = `El_end);
    l
  | _ as signal ->
    let str = Xml.string_of_signal signal in
    let (mfns, mfname) = Elements.oeb_manifest in
    let elstr = ("namespace=" ^ mfns ^" name=" ^ mfname) in
    failwith ("Unexpected signal " ^ str ^ ", expected elemennt " ^ elstr)

let input_itemref i = match Xml.peek i with
  | `El_start (el, a) when el=Elements.oeb_itemref ->
    ignore (Xml.input_signal i);
    assert ((Xml.input_signal i) = `El_end);
    begin match a with
      | [(_,"idref"),idref_] -> Some idref_
      | _ -> failwith "itemref element has wrong list of attributes"
    end
  | _ -> None

let input_spine i = match Xml.input_signal i with
  | `El_start (el, []) when el=Elements.oeb_spine ->
    let l = Xml.input_list input_itemref i in
    assert (Xml.input_signal i = `El_end);
    l
  | _ -> failwith "Malformed XML document"

let dump_ ((ns,n),v) =
  Printf.fprintf stderr
    "Attribute %s in namespace %s with value %s\n"
    n ns v
  
let dump a =
  Printf.fprintf stderr "Package attributes are:\n";
  List.iter dump_ a

let readPackage d i =
  match Xml.input_signal i with
    | `El_start (el, a) when el=Elements.oeb_package ->
      let ui =
        try List.assoc Elements.oeb_unique_identifier a
        with Not_found ->
        begin
          dump a;
          failwith "The package element has no unique-identifier attribute"
        end
      in
      let (dcmd, xmd) = input_metadata i in
      let (mf, ncx_) = extract_ncx (input_manifest i) in
      let sp = input_spine i in
      assert ((Xml.input_signal i) = `El_end);
      {
        dtd = d;
        uniqueIdentifier = ui;
        dc = dcmd;
        x = xmd;
        manifest = mf;
        ncx = ncx_;
        spine = sp;
        tours = [];
        guide = []
      }
    | _ -> failwith "Malformed XML document" 

type 'a result =
  | R of 'a
  | E of exn

let load filename =
  let f i = match (Xml.input_signal i) with 
    | `Dtd (Some d) -> (readPackage d i ) 
    | _ -> failwith "The package file should conform to the right dtd and declare it"
  in let ic = open_in filename in
  let i = Xml.make_input ~strip:true (`Channel ic)
  in
  let r = try (R (f i)) with _ as e -> (E e)
  in close_in ic;
  match r with
    | R p -> p
    | E e -> raise e

let output_manifest_element o e =
  let attributes = 
  [
    ("","href"),e.href;
    ("","id"),e.id;
    ("","media-type"),e.mediaType
  ]
  in
  let t = (Elements.oeb_item, attributes) in
  Xml.output_empty_element o t

let output_manifest o manifest ncx =
  if List.exists is_ncx manifest then
  failwith "The manifest contains an item with id=ncx whereas this one should be stored in the ncx field"    
  else begin
    let ncx_item = {
      href = ncx.ncx_href;
      id = "ncx";
      mediaType = ncx.ncx_mediatype
    } in
    let t = Elements.oeb_manifest, [] in
    Xml.output_start_tag o t;
    List.iter (output_manifest_element o) (ncx_item :: manifest); 
    Xml.output_end_tag o; (* </manifest> *)
  end

let output_spine_element o idref =
  let t = Elements.oeb_itemref, [Elements.oeb_idref, idref] in
  Xml.output_empty_element o t

let save filename package =
  let oc = open_out filename in
  let o = Xml.make_output ~nl:true (`Channel oc) in
  Xml.output o (`Dtd (Some package.dtd));
  let rootAttributes =
  [
    Elements.oeb_unique_identifier, package.uniqueIdentifier;
    Namespaces.default_namespace_attribute Namespaces.oeb
  ] in
  Xml.output_start_tag o (Elements.oeb_package, rootAttributes);
  Xml.output_start_tag o (Elements.oeb_metadata, []);
  output_dc_metadata o package.dc;
  begin match package.x with
    | None -> ()
    | Some xmd -> output_dtb_metadata o xmd
  end;
  Xml.output_end_tag o; (* </metadata> *)
  output_manifest o package.manifest package.ncx;
  Xml.output_start_tag o (Elements.oeb_spine,  []);
  List.iter (output_spine_element o) package.spine;
  Xml.output_end_tag o; (* </spine> *)
  Xml.output_end_tag o; (* </package> *)
  close_out oc


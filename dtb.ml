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

type dtb_multimedia_type =
  | AudioOnly
  | AudioNCX
  | AudioPartText
  | AudioFullText
  | TextPartAudio
  | TextNCX
  
type dtb_metadata = {
  dtb_SourceDate : string option;
  dtb_SourceEdition : string option;
  dtb_SourcePublisher : string option;
  dtb_SourceRights : string option;
  dtb_SourceTitle : string option;
  dtb_MultimediaType : dtb_multimedia_type;
  dtb_MultimediaContent : string;
  dtb_Narrator : string option;
  dtb_Producer : string list;
  dtb_ProducedDate : string option;
  dtb_Revision : int option;
  dtb_RevisionDate : string option;
  dtb_RevisionDescription : string option;
  dtb_TotalTime : string;
  dtb_AudioFormat : string list;
  pdtb2_SpecVersion : string option;
  pdtb2_Package : string option;
  pdtb2_Authorization : string option
}

let dtb_metadata_initializer = {
  dtb_SourceDate = None;
  dtb_SourceEdition = None;
  dtb_SourcePublisher = None;
  dtb_SourceRights = None;
  dtb_SourceTitle = None;
  dtb_MultimediaType = TextNCX;
  dtb_MultimediaContent = "text";
  dtb_Narrator = None;
  dtb_Producer = [];
  dtb_ProducedDate = None;
  dtb_Revision = None;
  dtb_RevisionDate = None;
  dtb_RevisionDescription = None;
  dtb_TotalTime = "0:00:00";
  dtb_AudioFormat = [];
  pdtb2_SpecVersion = None;
  pdtb2_Package = None;
  pdtb2_Authorization = None
}

let multimedia_type_of_string = function
  | "audioOnly" -> AudioOnly
  | "audioNCX" -> AudioNCX
  | "audioPartText" -> AudioPartText
  | "audioFullText" -> AudioFullText
  | "textPartAudio" -> TextPartAudio
  | "textNCX" -> TextNCX
  | _ as s -> failwith ("Invalid multimedia type " ^ s)

let string_of_multimedia_type = function
  | AudioOnly -> "audioOnly"
  | AudioNCX -> "audioNCX"
  | AudioPartText -> "audioPartText"
  | AudioFullText -> "audioFullText"
  | TextPartAudio -> "textPartAudio"
  | TextNCX -> "textNCX"

let input_dtb_element i = match Xml.peek i with
  | `El_start ((_,"meta"),a) ->
    ignore (Xml.input_signal i);
    if (Xml.input_signal i) <> `El_end
    then failwith "meta element should be empty"
    else begin match a with
      | [((_,"name"),n);((_,"content"),c)] -> Some (n,c)
      | [((_,"content"),c);((_,"name"),n)] -> Some (n,c)
      | _ -> failwith "meta element has wrong list of attributes"
    end
  | _ -> None

let dtb_metadata_of_pairs pairs =
  let dtbMultimediaTypeSet = ref false in
  let dtbMultimediaContentSet = ref false in
  let dtbTotalTimeSet = ref false in
  let err_not_rep e =
    let msg = "The dtb element " ^ e ^ " appears more than once whereas it is not repeatable"
    in failwith msg
  in
  let update x (n,v) = match n with
    | "dtb:sourceDate" ->
      begin match x.dtb_SourceDate with
        | None -> { x with dtb_SourceDate=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:sourceEdition" ->
      begin match x.dtb_SourceEdition with
        | None -> { x with dtb_SourceEdition=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:sourcePublisher" ->
      begin match x.dtb_SourcePublisher with
        | None -> { x with dtb_SourcePublisher=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:sourceRights" ->
      begin match x.dtb_SourceRights with
        | None -> { x with dtb_SourceRights=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:sourceTitle" ->
      begin match x.dtb_SourceTitle with
        | None -> { x with dtb_SourceTitle=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:multimediaType" ->
      begin match !dtbMultimediaTypeSet with
        | false ->
          let v' = multimedia_type_of_string v in
          dtbMultimediaTypeSet := true;
          { x with dtb_MultimediaType = v' }
        | true -> err_not_rep n
      end
    | "dtb:multimediaContent" ->
      begin match !dtbMultimediaContentSet with
        | false ->
          dtbMultimediaContentSet := true;
          { x with dtb_MultimediaContent = v }
        | true -> err_not_rep n
      end
    | "dtb:narrator" ->
      begin match x.dtb_Narrator with
        | None -> { x with dtb_Narrator=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:producer" -> { x with dtb_Producer = v::x.dtb_Producer }
    | "dtb:producedDate" ->
      begin match x.dtb_ProducedDate with
        | None -> { x with dtb_ProducedDate=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:revision" ->
      begin match x.dtb_Revision with
        | None -> { x with dtb_Revision=Some (int_of_string v) }
        | Some _ -> err_not_rep n
      end
    | "dtb:revisionDate" ->
      begin match x.dtb_RevisionDate with
        | None -> { x with dtb_RevisionDate=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:revisionDescription" ->
      begin match x.dtb_RevisionDescription with
        | None -> { x with dtb_RevisionDescription=Some v }
        | Some _ -> err_not_rep n
      end
    | "dtb:totalTime" ->
      begin match !dtbTotalTimeSet with
        | false ->
          dtbTotalTimeSet := true;
          { x with dtb_TotalTime = v }
        | true -> err_not_rep n
      end
    | "dtb:audioFormat" -> { x with dtb_AudioFormat = v::x.dtb_AudioFormat }
    | _ -> failwith ("Unknown value for name attribute in meta element: " ^ n)
  in List.fold_left update dtb_metadata_initializer pairs

let check_dtb_metadata _ = true
 
let input_dtb_metadata i = match Xml.peek i with
  | `El_start ((_,"x-metadata"),_) ->
    ignore (Xml.input_signal i);
    let l = Xml.input_list input_dtb_element i in
    assert (Xml.input_signal i = `El_end);
    let result = dtb_metadata_of_pairs l in
    assert (check_dtb_metadata result);
    Some result
  | _ -> None

let output_meta_element o name content =
  let attributes = [("","name"),name;("","content"),content] in
  let t = Elements.oeb_meta, attributes in
  Xml.output_empty_element o t

let output_optional_meta_element o name = function
  | None -> ()
  | Some value -> output_meta_element o name value

let output_dtb_metadata o x =
  let f = function
    | None -> None
    | Some x -> Some (string_of_int x)
  in
  Xml.output_start_tag o (Elements.oeb_x_metadata, []);
  output_optional_meta_element o "dtb:sourceDate" x.dtb_SourceDate;
  output_optional_meta_element o "dtb:sourceEdition" x.dtb_SourceEdition;
  output_optional_meta_element o "dtb:sourcePublisher" x.dtb_SourcePublisher;
  output_optional_meta_element o "dtb:sourceRights" x.dtb_SourceRights;
  output_optional_meta_element o "dtb:sourceTitle" x.dtb_SourceTitle;
  output_meta_element o "dtb:multimediaType" (string_of_multimedia_type x.dtb_MultimediaType);
  output_meta_element o "dtb:multimediaContent" x.dtb_MultimediaContent;
  output_optional_meta_element o "dtb:narrator" x.dtb_Narrator;
  List.iter (output_meta_element o "dtb:producer") x.dtb_Producer;
  output_optional_meta_element o "dtb:producedDate" x.dtb_ProducedDate;
  output_optional_meta_element o "dtb:revision" (f x.dtb_Revision);
  output_optional_meta_element o "dtb:revisionDate" x.dtb_RevisionDate;
  output_optional_meta_element o "dtb:revisionDescription" x.dtb_RevisionDescription;
  output_meta_element o "dtb:totalTime" x.dtb_TotalTime;
  List.iter (output_meta_element o "dtb:audioFormat") x.dtb_AudioFormat;
  output_optional_meta_element o "pdtb2:specVersion" x.pdtb2_SpecVersion;
  output_optional_meta_element o "pdtb2:package" x.pdtb2_Package;
  output_optional_meta_element o "pdtb2:authorization" x.pdtb2_Authorization;
  Xml.output_end_tag o (* </x-metadata> *)  

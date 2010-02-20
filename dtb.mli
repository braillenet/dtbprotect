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

val dtb_metadata_initializer : dtb_metadata
val multimedia_type_of_string : string -> dtb_multimedia_type
val string_of_multimedia_type : dtb_multimedia_type -> string
val input_dtb_metadata : Xml.input -> dtb_metadata option
val output_dtb_metadata : Xml.output -> dtb_metadata -> unit


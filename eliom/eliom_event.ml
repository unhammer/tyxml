(* Ocsigen
 * http://www.ocsigen.org
 * Module server.ml
 * Copyright (C) 2010
 * Raphaël Proust
 * Laboratoire PPS - CNRS Université Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

(* Module for event wrapping and related functions *)


module Down =
struct

  let wrap ~sp e =
    let chan = Eliom_comet.Channels.create () in
    let () =
      let m = React.E.map (fun x -> Eliom_comet.Channels.write chan x) e in
      let `R k = React.E.retain e (fun () -> ()) in
        ignore (React.E.retain e (fun () -> k () ; ignore m ; ignore chan))
    in
      Eliom_client.wrap ~sp (Eliom_comet.Channels.get_id chan)

end



module Up =
struct

  type 'a event =
      'a React.event *
      (unit,
       'a,
       [ `Nonattached of [ `Post ] Eliom_services.na_s ],
       [ `WithoutSuffix ],
       unit,
       [`One of 'a] Eliom_parameters.param_name,
       [ `Registrable ],
       Eliom_predefmod.Action.return)
        Eliom_services.service

  let react_event_of_up_event = fst
  let wrap = snd

  (* An event is created along with a service responsible for it's occurences. 
   * function takes sp and a param_type *)
  let create ~sp post_param =
    let (e, push) = React.E.create () in
    let e_writer =
      Eliom_predefmod.Action.register_new_post_coservice'
        ~options:`NoReload
        ~sp
        ~post_params:post_param
        (fun _ () msg -> push msg ; Lwt.return ())
    in
      (e, e_writer)

end
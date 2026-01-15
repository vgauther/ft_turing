open Yojson.Basic
open Yojson.Basic.Util

type transition = {
  read : string;
  to_state : string;
  write : string;
  action : string;
}

type machine = {
  name : string;
  alphabet : string list;
  blank : string;
  states : string list;
  initial : string;
  finals : string list;
  transitions : (string * transition list) list;
}

let parse_transition json =
  {
    read = json |> member "read" |> to_string;
    to_state = json |> member "to_state" |> to_string;
    write = json |> member "write" |> to_string;
    action = json |> member "action" |> to_string;
  }

let parse_machine filename =
  let json = Yojson.Basic.from_file filename in

  let name = json |> member "name" |> to_string in
  let alphabet = json |> member "alphabet" |> to_list |> List.map to_string in
  let blank = json |> member "blank" |> to_string in
  let states = json |> member "states" |> to_list |> List.map to_string in
  let initial = json |> member "initial" |> to_string in
  let finals = json |> member "finals" |> to_list |> List.map to_string in

  let transitions =
    json |> member "transitions" |> to_assoc
    |> List.map (fun (state, lst) ->
        let trans =
          lst |> to_list |> List.map parse_transition
        in
        (state, trans)
      )
  in

  { name; alphabet; blank; states; initial; finals; transitions }

let print_list label lst =
  Printf.printf "%s: [ %s ]\n"
    label
    (String.concat ", " lst)

let print_machine m =
  print_list "Alphabet" m.alphabet;
  print_list "States " m.states;
  Printf.printf "Initial : %s\n" m.initial;
  print_list "Finals " m.finals;
  print_endline "";

  List.iter (fun (state, trans) ->
    List.iter (fun t ->
      Printf.printf "(%s, %s) -> (%s, %s, %s)\n"
        state t.read t.to_state t.write t.action
    ) trans
  ) m.transitions

let () =
  if Array.length Sys.argv <> 2 then (
    Printf.printf "usage: %s machine.json\n" Sys.argv.(0);
    exit 1
  );

  let machine = parse_machine Sys.argv.(1) in
  print_machine machine

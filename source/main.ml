open Parse

(** Affiche une liste sous la forme attendue par la sortie du programme. *)
let print_list label lst =
  Printf.printf "%s: [ %s ]\n"
    label
    (String.concat ", " lst)

(** Affiche les proprietes et l'ensemble des transitions d'une machine. *)
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

(** Verifie les arguments, charge la machine puis affiche sa description. *)
let run () =
  if Array.length Sys.argv <> 2 then (
    Printf.eprintf "usage: %s machine.json\n" Sys.argv.(0);
    exit 1
  );

  let machine = Parse.parse_machine Sys.argv.(1) in
  print_machine machine

(** Point d'entree : transforme les erreurs de parsing en messages lisibles. *)
let () =
  try run () with
  | Parse.Machine_error message ->
      Printf.eprintf "Error: invalid machine: %s\n" message;
      exit 1
  | Yojson.Json_error message ->
      Printf.eprintf "Error: invalid JSON: %s\n" message;
      exit 1
  | Sys_error message ->
      Printf.eprintf "Error: cannot read machine file: %s\n" message;
      exit 1
  | exception_value ->
      Printf.eprintf "Error: cannot parse machine: %s\n"
        (Printexc.to_string exception_value);
      exit 1

open Parse

(** Affiche l'aide de la ligne de commande dans le canal demande. *)
let print_usage channel =
  let program = Filename.basename Sys.argv.(0) in
  Printf.fprintf channel "usage: %s [-h] jsonfile input\n" program;
  Printf.fprintf channel "\npositional arguments:\n";
  Printf.fprintf channel "  jsonfile            json description of the machine\n";
  Printf.fprintf channel "  input               input of the machine\n";
  Printf.fprintf channel "\noptional arguments:\n";
  Printf.fprintf channel "  -h, --help          show this help message and exit\n"

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

(** Affiche le ruban, la position de la tete et la transition a appliquer. *)
let print_transition
    (configuration : Engine.configuration)
    (transition : Parse.transition) =
  Printf.printf "%s (%s, %s) -> (%s, %s, %s)\n%!"
    (Engine.render_tape ~padding:12 configuration.tape)
    configuration.state
    transition.read
    transition.to_state
    transition.write
    transition.action

(** Affiche la configuration atteinte lorsque la machine s'arrete. *)
let print_final_configuration (configuration : Engine.configuration) =
  Printf.printf "%s (%s)\n" (Engine.render_tape ~padding:12 configuration.tape)
    configuration.state;
  Printf.printf "Machine halted after %d transition(s).\n" configuration.steps

(** Verifie les arguments, charge la machine et lance son execution. *)
let run () =
  if
    Array.length Sys.argv = 2
    && (Sys.argv.(1) = "-h" || Sys.argv.(1) = "--help")
  then print_usage stdout
  else if Array.length Sys.argv <> 3 then (
    print_usage stderr;
    exit 1
  ) else
    let machine = Parse.parse_machine Sys.argv.(1) in
    let input = Sys.argv.(2) in
    print_machine machine;
    print_endline "";
    let final_configuration =
      Engine.run ~on_transition:print_transition machine input
    in
    print_final_configuration final_configuration

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
  | Engine.Engine_error message ->
      Printf.eprintf "Error: execution failed: %s\n" message;
      exit 1
  | exception_value ->
      Printf.eprintf "Error: unexpected failure: %s\n"
        (Printexc.to_string exception_value);
      exit 1

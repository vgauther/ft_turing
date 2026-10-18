(** Represente une transition elementaire de la machine de Turing. *)
type transition = {
  read : string;
  to_state : string;
  write : string;
  action : string;
}

(** Regroupe la description complete d'une machine apres validation. *)
type machine = {
  name : string;
  alphabet : string list;
  blank : string;
  states : string list;
  initial : string;
  finals : string list;
  transitions : (string * transition list) list;
}

(** Erreur levee lorsqu'une description de machine est invalide. *)
exception Machine_error of string

(** Construit et leve une [Machine_error] a partir d'un message formate. *)
let machine_error format =
  Printf.ksprintf (fun message -> raise (Machine_error message)) format

(** Retourne la premiere valeur presente plusieurs fois dans une liste. *)
let rec find_duplicate seen = function
  | [] -> None
  | value :: rest ->
      if List.mem value seen then Some value
      else find_duplicate (value :: seen) rest

(** Verifie qu'une liste ne contient aucun doublon. *)
let ensure_unique context values =
  match find_duplicate [] values with
  | Some value -> machine_error "%s contains duplicate value %S" context value
  | None -> ()

(** Extrait les champs d'un objet JSON ou signale une erreur de type. *)
let expect_object context = function
  | `Assoc fields -> fields
  | _ -> machine_error "%s must be a JSON object" context

(** Extrait les elements d'une liste JSON ou signale une erreur de type. *)
let expect_list context = function
  | `List values -> values
  | _ -> machine_error "%s must be a JSON list" context

(** Extrait une chaine JSON ou signale une erreur de type. *)
let expect_string context = function
  | `String value -> value
  | _ -> machine_error "%s must be a string" context

(** Verifie que les champs JSON attendus sont presents, uniques et les seuls
    autorises. *)
let ensure_fields context expected fields =
  let field_names = List.map fst fields in
  ensure_unique (context ^ " fields") field_names;
  List.iter
    (fun field ->
      if not (List.mem field expected) then
        machine_error "%s contains unknown field %S" context field)
    field_names;
  List.iter
    (fun field ->
      if not (List.mem field field_names) then
        machine_error "%s is missing required field %S" context field)
    expected

(** Recupere un champ obligatoire dans une liste de champs JSON. *)
let get_field context field fields =
  match List.assoc_opt field fields with
  | Some value -> value
  | None -> machine_error "%s is missing required field %S" context field

(** Convertit une liste JSON en liste de chaines en indiquant l'index invalide. *)
let parse_string_list context json =
  json
  |> expect_list context
  |> List.mapi (fun index value ->
         expect_string
           (Printf.sprintf "%s item %d" context (index + 1))
           value)

(** Convertit et valide la structure JSON d'une transition. *)
let parse_transition state index json =
  let context =
    Printf.sprintf "transition %d of state %S" (index + 1) state
  in
  let fields = expect_object context json in
  ensure_fields context ["read"; "to_state"; "write"; "action"] fields;
  {
    read = get_field context "read" fields |> expect_string (context ^ ".read");
    to_state =
      get_field context "to_state" fields
      |> expect_string (context ^ ".to_state");
    write =
      get_field context "write" fields |> expect_string (context ^ ".write");
    action =
      get_field context "action" fields |> expect_string (context ^ ".action");
  }

(** Convertit l'objet JSON [transitions] en transitions groupees par etat. *)
let parse_transitions json =
  let fields = expect_object "transitions" json in
  ensure_unique "transitions" (List.map fst fields);
  List.map
    (fun (state, value) ->
      let transitions =
        value
        |> expect_list (Printf.sprintf "transitions for state %S" state)
        |> List.mapi (parse_transition state)
      in
      (state, transitions))
    fields

(** Indique si une chaine appartient a une liste de chaines. *)
let contains value values =
  List.exists (String.equal value) values

(** Controle la coherence metier de la machine et de toutes ses transitions. *)
let validate_machine machine =
  ensure_unique "alphabet" machine.alphabet;
  ensure_unique "states" machine.states;
  ensure_unique "finals" machine.finals;
  List.iter
    (fun symbol ->
      if String.length symbol <> 1 then
        machine_error "alphabet symbol %S must have a length of exactly 1" symbol)
    machine.alphabet;
  if String.length machine.blank <> 1 then
    machine_error "blank symbol %S must have a length of exactly 1" machine.blank;
  if not (contains machine.blank machine.alphabet) then
    machine_error "blank symbol %S is not part of the alphabet" machine.blank;
  if not (contains machine.initial machine.states) then
    machine_error "initial state %S is not part of states" machine.initial;
  List.iter
    (fun final ->
      if not (contains final machine.states) then
        machine_error "final state %S is not part of states" final)
    machine.finals;
  List.iter
    (fun (state, transitions) ->
      if not (contains state machine.states) then
        machine_error "transition source state %S is not part of states" state;
      ensure_unique
        (Printf.sprintf "transitions for state %S" state)
        (List.map (fun transition -> transition.read) transitions);
      List.iter
        (fun transition ->
          if not (contains transition.read machine.alphabet) then
            machine_error
              "transition from state %S reads symbol %S outside the alphabet"
              state transition.read;
          if not (contains transition.write machine.alphabet) then
            machine_error
              "transition from state %S writes symbol %S outside the alphabet"
              state transition.write;
          if not (contains transition.to_state machine.states) then
            machine_error
              "transition from state %S targets unknown state %S"
              state transition.to_state;
          if transition.action <> "LEFT" && transition.action <> "RIGHT" then
            machine_error
              "transition from state %S has invalid action %S (expected LEFT or RIGHT)"
              state transition.action)
        transitions)
    machine.transitions

(** Charge un fichier JSON, construit la machine puis applique toutes les
    validations de structure et de coherence. *)
let parse_machine filename =
  if not (Filename.check_suffix filename ".json") then
    machine_error "machine file %S must have a .json extension" filename;
  let json = Yojson.Basic.from_file filename in
  let context = "machine" in
  let fields = expect_object context json in
  ensure_fields context
    ["name"; "alphabet"; "blank"; "states"; "initial"; "finals";
     "transitions"]
    fields;
  let machine =
    {
      name = get_field context "name" fields |> expect_string "name";
      alphabet =
        get_field context "alphabet" fields |> parse_string_list "alphabet";
      blank = get_field context "blank" fields |> expect_string "blank";
      states = get_field context "states" fields |> parse_string_list "states";
      initial = get_field context "initial" fields |> expect_string "initial";
      finals = get_field context "finals" fields |> parse_string_list "finals";
      transitions =
        get_field context "transitions" fields |> parse_transitions;
    }
  in
  validate_machine machine;
  machine

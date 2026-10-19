(** Ruban fonctionnel centre sur la position actuelle de la tete.
    [left] est stocke dans l'ordre inverse pour deplacer la tete en temps
    constant. Une liste vide represente la partie encore infinie du ruban. *)
type tape = {
  left : string list;
  current : string;
  right : string list;
  blank : string;
}

(** Etat complet d'une execution a un instant donne. *)
type configuration = {
  state : string;
  tape : tape;
  steps : int;
}

(** Erreur levee lorsque l'entree est invalide ou que la machine est bloquee. *)
exception Engine_error of string

(** Construit et leve une [Engine_error] a partir d'un message formate. *)
let engine_error format =
  Printf.ksprintf (fun message -> raise (Engine_error message)) format

(** Convertit la chaine d'entree en une liste de symboles d'un caractere. *)
let symbols_of_input input =
  List.init (String.length input) (fun index -> String.make 1 input.[index])

(** Verifie que l'entree ne contient ni le symbole vide ni un symbole absent
    de l'alphabet de la machine. *)
let validate_input (machine : Parse.machine) symbols =
  List.iter
    (fun symbol ->
      if String.equal symbol machine.blank then
        engine_error "input must not contain the blank symbol %S" machine.blank;
      if not (List.exists (String.equal symbol) machine.alphabet) then
        engine_error "input symbol %S is not part of the alphabet" symbol)
    symbols

(** Cree un ruban dont la tete pointe sur le premier symbole de l'entree.
    Une entree vide place directement la tete sur une case vide. *)
let tape_of_symbols blank = function
  | [] -> { left = []; current = blank; right = []; blank }
  | current :: right -> { left = []; current; right; blank }

(** Construit et valide le ruban initial a partir de l'entree utilisateur. *)
let tape_of_input (machine : Parse.machine) input =
  let symbols = symbols_of_input input in
  validate_input machine symbols;
  tape_of_symbols machine.blank symbols

(** Deplace la tete vers la gauche. Si aucune case n'a encore ete visitee de
    ce cote, une nouvelle case contenant le symbole vide est creee. *)
let move_left tape =
  match tape.left with
  | next :: rest ->
      { tape with
        left = rest;
        current = next;
        right = tape.current :: tape.right }
  | [] ->
      { tape with
        current = tape.blank;
        right = tape.current :: tape.right }

(** Deplace la tete vers la droite. Si aucune case n'a encore ete visitee de
    ce cote, une nouvelle case contenant le symbole vide est creee. *)
let move_right tape =
  match tape.right with
  | next :: rest ->
      { tape with
        left = tape.current :: tape.left;
        current = next;
        right = rest }
  | [] ->
      { tape with
        left = tape.current :: tape.left;
        current = tape.blank }

(** Ecrit le symbole demande puis deplace la tete selon la transition recue. *)
let apply_transition tape (transition : Parse.transition) =
  let written_tape = { tape with current = transition.write } in
  match transition.action with
  | "LEFT" -> move_left written_tape
  | "RIGHT" -> move_right written_tape
  | action -> engine_error "unsupported transition action %S" action

(** Indique si l'etat donne est un etat final de la machine. *)
let is_final (machine : Parse.machine) state =
  List.exists (String.equal state) machine.finals

(** Recherche la transition correspondant a l'etat et au symbole courants.
    L'absence de transition est consideree comme un blocage de la machine. *)
let find_transition (machine : Parse.machine) state symbol =
  match List.assoc_opt state machine.transitions with
  | None -> engine_error "machine is blocked: state %S has no transitions" state
  | Some transitions ->
      match
        List.find_opt
          (fun (transition : Parse.transition) ->
            String.equal transition.read symbol)
          transitions
      with
      | Some transition -> transition
      | None ->
          engine_error
            "machine is blocked: no transition for state %S and symbol %S"
            state symbol

(** Applique une transition a une configuration et construit l'etape suivante. *)
let next_configuration configuration transition =
  {
    state = transition.Parse.to_state;
    tape = apply_transition configuration.tape transition;
    steps = configuration.steps + 1;
  }

(** Execute la machine depuis une configuration existante jusqu'a un etat
    final. [on_transition] est appelee avant chaque transition afin de pouvoir
    afficher ou enregistrer l'etat du ruban. *)
let run_from_configuration
    ?(on_transition = fun _configuration _transition -> ())
    (machine : Parse.machine) initial_configuration =
  let rec loop configuration =
    if is_final machine configuration.state then configuration
    else
      let transition =
        find_transition machine configuration.state configuration.tape.current
      in
      on_transition configuration transition;
      loop (next_configuration configuration transition)
  in
  loop initial_configuration

(** Initialise le ruban et execute la machine jusqu'a son etat final. *)
let run ?(on_transition = fun _configuration _transition -> ())
    (machine : Parse.machine) input =
  let initial_configuration =
    {
      state = machine.initial;
      tape = tape_of_input machine input;
      steps = 0;
    }
  in
  run_from_configuration ~on_transition machine initial_configuration

(** Produit une representation finie du ruban avec la tete entre chevrons.
    [padding] ajoute des cases vides a droite pour rappeler que le ruban est
    infini sans tenter de l'afficher entierement. *)
let render_tape ?(padding = 8) tape =
  let left = List.rev tape.left |> String.concat "" in
  let right = tape.right |> String.concat "" in
  let blanks =
    List.init (max 0 padding) (fun _ -> tape.blank) |> String.concat ""
  in
  Printf.sprintf "[%s<%s>%s%s]" left tape.current right blanks

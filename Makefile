NAME = ft_turing

SRC_DIR = source
BUILD_DIR = build
NATIVE_BUILD_DIR = $(BUILD_DIR)/native
BYTE_BUILD_DIR = $(BUILD_DIR)/byte
SRC = parse.ml engine.ml main.ml
NATIVE_OBJ = $(SRC:%.ml=$(NATIVE_BUILD_DIR)/%.cmx)
BYTE_OBJ = $(SRC:%.ml=$(BYTE_BUILD_DIR)/%.cmo)
NATIVE_BIN = $(NATIVE_BUILD_DIR)/$(NAME)
BYTE_BIN = $(BYTE_BUILD_DIR)/$(NAME)

OCAMLFIND = ocamlfind
OCAMLOPT = ocamlopt
OCAMLC = ocamlc
PKGS = yojson

RESET = \033[0m
GREEN = \033[1;32m
YELLOW = \033[1;33m
BLUE = \033[1;34m
CYAN = \033[1;36m
RED = \033[1;31m

# Selectionne automatiquement le compilateur natif, puis le bytecode en
# solution de repli lorsque ocamlopt n'est pas disponible.
all: deps
	@if opam exec -- $(OCAMLFIND) $(OCAMLOPT) -version >/dev/null 2>&1; then \
		printf "$(CYAN)[MODE]$(RESET) Compilation native avec $(OCAMLOPT).\n"; \
		$(MAKE) --no-print-directory _native; \
	elif opam exec -- $(OCAMLFIND) $(OCAMLC) -version >/dev/null 2>&1; then \
		printf "$(YELLOW)[FALLBACK]$(RESET) $(OCAMLOPT) indisponible, compilation bytecode avec $(OCAMLC).\n"; \
		$(MAKE) --no-print-directory _byte; \
	else \
		printf "$(RED)[ERROR]$(RESET) Aucun compilateur OCaml utilisable n'a ete trouve.\n" >&2; \
		exit 1; \
	fi

# Verifie OPAM et les bibliotheques communes aux deux modes de compilation.
deps:
	@printf "$(CYAN)[CHECK]$(RESET) Verification d'OPAM, d'OCaml et de Yojson...\n"
	@if ! command -v opam >/dev/null 2>&1 \
		|| ! opam exec -- $(OCAMLFIND) query $(PKGS) >/dev/null 2>&1 \
		|| { ! opam exec -- $(OCAMLOPT) -version >/dev/null 2>&1 \
			&& ! opam exec -- $(OCAMLC) -version >/dev/null 2>&1; }; then \
		printf "$(YELLOW)[INSTALL]$(RESET) Une dependance manque, lancement de install.sh...\n"; \
		./install.sh; \
		printf "$(GREEN)[OK]$(RESET) Les dependances sont installees.\n"; \
	else \
		printf "$(GREEN)[OK]$(RESET) Toutes les dependances sont disponibles.\n"; \
	fi

# Force la compilation native et echoue clairement si ocamlopt est absent.
native: deps
	@if ! opam exec -- $(OCAMLFIND) $(OCAMLOPT) -version >/dev/null 2>&1; then \
		printf "$(RED)[ERROR]$(RESET) $(OCAMLOPT) est requis par la cible native.\n" >&2; \
		exit 1; \
	fi
	@printf "$(CYAN)[MODE]$(RESET) Compilation native avec $(OCAMLOPT).\n"
	@$(MAKE) --no-print-directory _native

# Force la compilation bytecode et echoue clairement si ocamlc est absent.
byte: deps
	@if ! opam exec -- $(OCAMLFIND) $(OCAMLC) -version >/dev/null 2>&1; then \
		printf "$(RED)[ERROR]$(RESET) $(OCAMLC) est requis par la cible byte.\n" >&2; \
		exit 1; \
	fi
	@printf "$(CYAN)[MODE]$(RESET) Compilation bytecode avec $(OCAMLC).\n"
	@$(MAKE) --no-print-directory _byte

$(NATIVE_BUILD_DIR) $(BYTE_BUILD_DIR):
	@printf "$(CYAN)[DIR]$(RESET) Creation du dossier $@/...\n"
	@mkdir -p $@

$(NATIVE_BUILD_DIR)/parse.cmx: $(SRC_DIR)/parse.ml | $(NATIVE_BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) $< avec $(OCAMLOPT)...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLOPT) -package $(PKGS) \
		-I $(NATIVE_BUILD_DIR) -c $< -o $@

$(NATIVE_BUILD_DIR)/engine.cmx: $(SRC_DIR)/engine.ml \
		$(NATIVE_BUILD_DIR)/parse.cmx | $(NATIVE_BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) $< avec $(OCAMLOPT)...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLOPT) -package $(PKGS) \
		-I $(NATIVE_BUILD_DIR) -c $< -o $@

$(NATIVE_BUILD_DIR)/main.cmx: $(SRC_DIR)/main.ml \
		$(NATIVE_BUILD_DIR)/parse.cmx $(NATIVE_BUILD_DIR)/engine.cmx \
		| $(NATIVE_BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) $< avec $(OCAMLOPT)...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLOPT) -package $(PKGS) \
		-I $(NATIVE_BUILD_DIR) -c $< -o $@

$(NATIVE_BIN): $(NATIVE_OBJ)
	@printf "$(BLUE)[LINK]$(RESET) Creation de l'executable natif...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLOPT) -linkpkg -package $(PKGS) \
		-I $(NATIVE_BUILD_DIR) $(NATIVE_OBJ) -o $@

$(BYTE_BUILD_DIR)/parse.cmo: $(SRC_DIR)/parse.ml | $(BYTE_BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) $< avec $(OCAMLC)...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLC) -package $(PKGS) \
		-I $(BYTE_BUILD_DIR) -c $< -o $@

$(BYTE_BUILD_DIR)/engine.cmo: $(SRC_DIR)/engine.ml \
		$(BYTE_BUILD_DIR)/parse.cmo | $(BYTE_BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) $< avec $(OCAMLC)...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLC) -package $(PKGS) \
		-I $(BYTE_BUILD_DIR) -c $< -o $@

$(BYTE_BUILD_DIR)/main.cmo: $(SRC_DIR)/main.ml \
		$(BYTE_BUILD_DIR)/parse.cmo $(BYTE_BUILD_DIR)/engine.cmo \
		| $(BYTE_BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) $< avec $(OCAMLC)...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLC) -package $(PKGS) \
		-I $(BYTE_BUILD_DIR) -c $< -o $@

$(BYTE_BIN): $(BYTE_OBJ)
	@printf "$(BLUE)[LINK]$(RESET) Creation de l'executable bytecode...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLC) -linkpkg -package $(PKGS) \
		-I $(BYTE_BUILD_DIR) $(BYTE_OBJ) -o $@

# Expose l'executable choisi a la racine sans le recopier s'il est deja a jour.
_native: $(NATIVE_BIN)
	@if [ ! -f $(NAME) ] || ! cmp -s $(NATIVE_BIN) $(NAME); then \
		cp $(NATIVE_BIN) $(NAME); \
		printf "$(GREEN)[OK]$(RESET) Executable natif $(NAME) cree avec succes.\n"; \
	else \
		printf "$(GREEN)[READY]$(RESET) $(NAME) natif est deja a jour.\n"; \
	fi

_byte: $(BYTE_BIN)
	@if [ ! -f $(NAME) ] || ! cmp -s $(BYTE_BIN) $(NAME); then \
		cp $(BYTE_BIN) $(NAME); \
		printf "$(GREEN)[OK]$(RESET) Executable bytecode $(NAME) cree avec succes.\n"; \
	else \
		printf "$(GREEN)[READY]$(RESET) $(NAME) bytecode est deja a jour.\n"; \
	fi

clean:
	@printf "$(YELLOW)[CLEAN]$(RESET) Suppression des fichiers de compilation...\n"
	@rm -rf $(BUILD_DIR)
	@printf "$(GREEN)[OK]$(RESET) Fichiers de compilation supprimes.\n"

fclean: clean
	@printf "$(YELLOW)[FCLEAN]$(RESET) Suppression de l'executable $(NAME)...\n"
	@rm -f $(NAME)
	@printf "$(GREEN)[OK]$(RESET) Nettoyage complet termine.\n"

re: fclean all
	@printf "$(GREEN)[OK]$(RESET) Projet entierement recompile.\n"

.PHONY: all deps native byte _native _byte clean fclean re

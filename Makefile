NAME = ft_turing
SRC_DIR = source
BUILD_DIR = build
SRC = parse.ml main.ml
CMX = $(SRC:%.ml=$(BUILD_DIR)/%.cmx)

OCAMLFIND = ocamlfind
OCAMLOPT = ocamlopt
PKGS = yojson

RESET = \033[0m
GREEN = \033[1;32m
YELLOW = \033[1;33m
BLUE = \033[1;34m
CYAN = \033[1;36m

all: $(NAME)
	@printf "$(GREEN)[READY]$(RESET) $(NAME) est à jour.\n"

deps:
	@printf "$(CYAN)[CHECK]$(RESET) Vérification d'OPAM, d'OCaml et de Yojson...\n"
	@if ! command -v opam >/dev/null 2>&1 \
		|| ! opam exec -- $(OCAMLFIND) query $(PKGS) >/dev/null 2>&1 \
		|| ! opam exec -- $(OCAMLOPT) -version >/dev/null 2>&1; then \
		printf "$(YELLOW)[INSTALL]$(RESET) Une dépendance manque, lancement de install.sh...\n"; \
		./install.sh; \
		printf "$(GREEN)[OK]$(RESET) Les dépendances sont installées.\n"; \
	else \
		printf "$(GREEN)[OK]$(RESET) Toutes les dépendances sont disponibles.\n"; \
	fi

$(BUILD_DIR):
	@printf "$(CYAN)[DIR]$(RESET) Création du dossier $(BUILD_DIR)/...\n"
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/parse.cmx: $(SRC_DIR)/parse.ml | deps $(BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) Compilation de $<...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLOPT) -package $(PKGS) \
		-I $(BUILD_DIR) -c $< -o $@

$(BUILD_DIR)/main.cmx: $(SRC_DIR)/main.ml $(BUILD_DIR)/parse.cmx | deps $(BUILD_DIR)
	@printf "$(BLUE)[COMPILE]$(RESET) Compilation de $<...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLOPT) -package $(PKGS) \
		-I $(BUILD_DIR) -c $< -o $@

$(NAME): $(CMX) | deps
	@printf "$(BLUE)[LINK]$(RESET) Création de l'exécutable $(NAME)...\n"
	@opam exec -- $(OCAMLFIND) $(OCAMLOPT) -linkpkg -package $(PKGS) \
		-I $(BUILD_DIR) $(CMX) -o $(NAME)
	@printf "$(GREEN)[OK]$(RESET) Exécutable $(NAME) créé avec succès.\n"

clean:
	@printf "$(YELLOW)[CLEAN]$(RESET) Suppression des fichiers de compilation...\n"
	@rm -rf $(BUILD_DIR)
	@printf "$(GREEN)[OK]$(RESET) Fichiers de compilation supprimés.\n"

fclean: clean
	@printf "$(YELLOW)[FCLEAN]$(RESET) Suppression de l'exécutable $(NAME)...\n"
	@rm -f $(NAME)
	@printf "$(GREEN)[OK]$(RESET) Nettoyage complet terminé.\n"

re: fclean all
	@printf "$(GREEN)[OK]$(RESET) Projet entièrement recompilé.\n"

.PHONY: all deps clean fclean re

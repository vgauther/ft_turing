NAME = ft_turing
SRC = main.ml

OCAMLFIND = ocamlfind
OCAMLOPT = ocamlopt
PKGS = yojson

all: $(NAME)

$(NAME):
	$(OCAMLFIND) $(OCAMLOPT) -linkpkg -package $(PKGS) $(SRC) -o $(NAME)

clean:
	rm -f *.cmx *.cmi *.o

fclean: clean
	rm -f $(NAME)

re: fclean all

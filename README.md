# ft_turing

Ce projet charge la description JSON d'une machine de Turing, verifie sa
coherence, puis affiche ses proprietes et ses transitions.

## Exemple commente : `unary_sub`

La machine `unary_sub`, fournie dans le sujet, realise une soustraction en
representation unaire. La valeur d'un nombre correspond au nombre de symboles
`1`. Par exemple, l'entree `111-11=` represente `3 - 2` et doit laisser une
unite comme resultat.

> Les commentaires `//` ci-dessous servent uniquement a la documentation.
> Le format JSON standard ne supporte pas les commentaires. Le fichier
> executable sans commentaires se trouve dans `machines/unary_sub.json`.

```jsonc
{
    // Nom utilise pour identifier et afficher la machine.
    "name": "unary_sub",

    // Ensemble des symboles autorises sur le ruban.
    "alphabet": [
        "1", // Unite utilisee pour representer les nombres.
        ".", // Case vide du ruban.
        "-", // Separateur entre les deux nombres.
        "="  // Marque la fin de l'expression.
    ],

    // Symbole utilise pour representer une case vide.
    // Il doit obligatoirement appartenir a l'alphabet.
    "blank": ".",

    // Liste exhaustive des etats que la machine peut utiliser.
    "states": [
        "scanright", // Parcourt le ruban vers la droite jusqu'au symbole =.
        "eraseone", // Retire une unite du second nombre ou termine le calcul.
        "subone",   // Revient vers le separateur -.
        "skip",     // Cherche une unite du premier nombre a supprimer.
        "HALT"      // Etat final : la machine s'arrete.
    ],

    // Etat dans lequel la machine commence son execution.
    "initial": "scanright",

    // Etats qui provoquent l'arret de la machine.
    "finals": [
        "HALT"
    ],

    // Les transitions sont regroupees par etat courant.
    "transitions": {
        // Avance jusqu'au marqueur de fin =.
        "scanright": [
            {
                // Traverse les cases deja effacees lors des cycles precedents.
                "read": ".",
                "to_state": "scanright", // Continue le parcours.
                "write": ".",            // Laisse la case vide.
                "action": "RIGHT"        // Avance vers la droite.
            },
            {
                // Traverse une unite sans la modifier.
                "read": "1",
                "to_state": "scanright", // Continue le parcours.
                "write": "1",            // Conserve l'unite.
                "action": "RIGHT"        // Avance vers la droite.
            },
            {
                // Traverse le separateur entre les deux nombres.
                "read": "-",
                "to_state": "scanright", // Continue vers le second nombre.
                "write": "-",            // Conserve le separateur.
                "action": "RIGHT"        // Avance vers la droite.
            },
            {
                // Efface l'ancien marqueur de fin et examine la case precedente.
                "read": "=",
                "to_state": "eraseone", // Prepare le retrait d'une unite.
                "write": ".",           // Efface l'ancien marqueur =.
                "action": "LEFT"        // Revient d'une case vers la gauche.
            }
        ],

        // Retire une unite du second nombre a chaque cycle.
        "eraseone": [
            {
                // Deplace le marqueur = d'une case vers la gauche.
                "read": "1",
                "to_state": "subone", // Commence le retour vers le separateur.
                "write": "=",         // Remplace cette unite par le nouveau =.
                "action": "LEFT"      // Repart vers la gauche.
            },
            {
                // Le second nombre est vide : le calcul est termine.
                "read": "-",
                "to_state": "HALT", // Entre dans l'etat final.
                "write": ".",       // Efface le separateur -.
                "action": "LEFT"    // Se place sur le resultat.
            }
        ],

        // Revient vers le separateur apres avoir retire une unite a droite.
        "subone": [
            {
                // Traverse les unites restantes du second nombre.
                "read": "1",
                "to_state": "subone", // Continue vers le separateur.
                "write": "1",         // Conserve l'unite.
                "action": "LEFT"      // Avance vers la gauche.
            },
            {
                // Le separateur est atteint : il faut retirer une unite a gauche.
                "read": "-",
                "to_state": "skip", // Passe a la recherche dans le premier nombre.
                "write": "-",       // Conserve le separateur.
                "action": "LEFT"    // Entre dans le premier nombre.
            }
        ],

        // Cherche la prochaine unite disponible dans le premier nombre.
        "skip": [
            {
                // Ignore les unites du premier nombre deja effacees.
                "read": ".",
                "to_state": "skip", // Continue la recherche.
                "write": ".",       // Laisse la case vide.
                "action": "LEFT"    // Avance vers la gauche.
            },
            {
                // Retire une unite du premier nombre puis recommence un cycle.
                "read": "1",
                "to_state": "scanright", // Repart vers le marqueur =.
                "write": ".",            // Efface une unite du premier nombre.
                "action": "RIGHT"        // Repart vers la droite.
            }
        ]
    }
}
```

## Lecture d'une transition

Chaque transition suit la forme suivante :

```text
(etat courant, symbole lu)
    -> (nouvel etat, symbole ecrit, direction)
```

Par exemple :

```text
(eraseone, 1) -> (subone, =, LEFT)
```

Lorsque la machine est dans l'etat `eraseone` et lit `1`, elle remplace cette
unite par le nouveau marqueur `=`, deplace sa tete vers la gauche et entre dans
l'etat `subone`.

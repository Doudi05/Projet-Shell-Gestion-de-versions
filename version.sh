#!/bin/dash   

# projet version.sh 
# Akel Ward , Aiach Rami , TD2/TP2B

# Permet l'affichage de la commande help quand on en a besoin 
# pas de paramètres attendu
usage (){
    echo "usage:
        ./version.sh --help
        ./version.sh <command> FILE [OPTION]
        where <command> can be: add amend checkout|co commit|ci diff log reset rm"

    echo "./version.sh add FILE MESSAGE
            Add FILE under versioning with the initial log message MESSAGE"

    echo "./version.sh commit|ci FILE MESSAGE
            Commit a new version of FILE with the log message MESSAGE"

    echo "./version.sh amend FILE MESSAGE
            Modify the last registered version of FILE, or (inclusive) its log message"

    echo "./version.sh checkout|co FILE [NUMBER]
            Restore FILE in the version NUMBER indicated, or in the
            latest version if there is no number passed in argument"

    echo "./version.sh diff FILE
            Displays the difference between FILE and the last committed version"

    echo "./version.sh log FILE
            Displays the logs of the versions already committed"

    echo "./version.sh reset FILE NUMBER
            Restores FILE in the version NUMBER indicated and
            deletes the versions of number strictly superior to NUMBER"

    echo "./version.sh rm FILE
            Deletes all versions of a file under versioning"
}


# affiche l'aide
help (){
    echo "Entrer ./version.sh --help for more information." >&2
}


# Usage : ./version.sh add FILE MESSAGE
# FILE est le nom du fichier à ajouter sous versioning.
# MESSAGE est le message de log associé à la première version du fichier.
# Le fichier doit être ajouté dans le répertoire .versioning du répertoire courant.

addCommande (){
    # Vérifier les arguments
    if [ $# -ne 2 ]; then
        echo "Usage : $0 add FILE MESSAGE"
        exit 1
    fi

    # Vérifier si le fichier existe
    if [ ! -f "$1" ]; then
        echo "Erreur : $1 n'est pas un fichier valide"
        exit 1
    fi

    # Créer le répertoire .versioning s'il n'existe pas
    if [ ! -d ".versioning" ]; then
        mkdir .versioning
    fi

    # Copier le fichier dans le répertoire .versioning
    cp "$1" ".versioning/$1.v1"

    # Écrire le message de log associé à la première version
    echo "$2" > ".versioning/$1.log"

    echo "Le fichier $1 a été ajouté sous versioning avec succès"
}


# Usage : ./version.sh rm FILE
# FILE est le nom du fichier à supprimer sous versioning.

rmCommande (){
    # Vérifier les arguments
    if [ $# -ne 1 ]; then
        echo "Usage : $0 rm FILE"
        exit 1
    fi

    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.v1" ]; then
        echo "Erreur : $1 n'est pas sous versioning"
        exit 1
    fi

    # Demander une confirmation à l'utilisateur
    echo "Êtes-vous sûr de vouloir supprimer toutes les versions de $1 ? (y/n)"
    read confirmation

    # Vérifier la sensibilité à la casse de la réponse
    if [ "$confirmation" != "y" || "$confirmation" != "Y" ]; then
        echo "Suppression annulée"
        exit 0
    else
        # Supprimer toutes les versions du fichier
        rm .versioning/$1.*

        echo "Toutes les versions de $1 ont été supprimées avec succès"

        # Vérifier si le répertoire .versioning est vide et le supprimer le cas échéant
        if [ -z "$(ls -A .versioning)" ]; then
            rm -r .versioning
            echo "Le répertoire .versioning a été supprimé avec succès"
        fi
    fi
}


# Usage : ./version.sh commit|ci FILE MESSAGE
# FILE est le nom du fichier à sauvegarder sous versioning.
# MESSAGE est le message de log associé à la nouvelle version du fichier.

commitCommande (){
    # Vérifier les arguments
    if [ $# -ne 2 ]; then
        echo "Usage : $0 commit|ci FILE MESSAGE"
        exit 1
    fi

    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.v1" ]; then
        echo "Erreur : $1 n'est pas sous versioning"
        exit 1
    fi

    # Vérifier si le fichier courant est identique à la dernière version
    if cmp -s "$1" ".versioning/$1.v1"; then
        echo "Le fichier $1 n'a pas été modifié"
        exit 0
    fi

    # Vérifier le numéro de la dernière version
    last_version=$(ls -1 .versioning | grep "$1.v" | sort -n | tail -1 | cut -d'.' -f3 | cut -d'v' -f2)
    
    echo "Le numéro de la dernière version est : $last_version"

    # Sauvegarder la nouvelle version
    cp "$1" ".versioning/$1.v$((last_version + 1))"

    # Écrire le message de log associé à la nouvelle version
    echo "$2" >> ".versioning/$1.log"

    echo "La nouvelle version du fichier $1 a été sauvegardée avec succès"
}


# Usage : ./version.sh diff FILE
# FILE est le nom du fichier à comparer.

diffCommande (){
    # Vérifier les arguments
    if [ $# -ne 1 ]; then
        echo "Usage : $0 diff FILE"
        exit 1
    fi

    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.v1" ]; then
        echo "Erreur : $1 n'est pas sous versioning"
        exit 1
    fi

    # Vérifier le numéro de la dernière version
    last_version=$(ls -1 .versioning | grep "$1.v" | sort -n | tail -1 | cut -d'.' -f3 | cut -d'v' -f2)

    # Vérifier si le fichier courant est identique à la dernière version
    if cmp -s "$1" ".versioning/$1.v$last_version"; then
        echo "Le fichier $1 n'a pas été modifié"
        echo "Il n'y a pas de différence entre la dernière version et le fichier courant"
        exit 0
    else
        # Afficher la différence entre le fichier courant et la dernière version
        diff "$1" ".versioning/$1.v$last_version"
    fi
}


# Usage : ./version.sh checkout|co FILE [NUMBER]
# FILE est le nom du fichier à restaurer.
# NUMBER est le numéro de la version à restaurer.

checkoutCommande (){
    # Vérifier les arguments
    if [ $# -ne 1 ] && [ $# -ne 2 ]; then
        echo "Usage : $0 checkout|co FILE [NUMBER]"
        exit 1
    fi

    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.v1" ]; then
        echo "Erreur : $1 n'est pas sous versioning"
        exit 1
    fi

    # Vérifier le numéro de la dernière version
    last_version=$(ls -1 .versioning | grep "$1.v" | sort -n | tail -1 | cut -d'.' -f3 | cut -d'v' -f2)

    # Vérifier si le fichier courant est identique à la dernière version
    if cmp -s "$1" ".versioning/$1.v$last_version"; then
        echo "Le fichier $1 n'a pas été modifié"
        echo "Il n'y a pas de différence entre la dernière version et le fichier courant"
        exit 0
    fi

    # Vérifier si le numéro de version est spécifié
    if [ $# -eq 2 ]; then
        # Vérifier si le numéro de version est valide
        if [ $2 -lt 1 ] || [ $2 -gt $last_version ]; then
            echo "Erreur : le numéro de version doit être compris entre 1 et $last_version"
            exit 1
        fi

        # Restaurer la version spécifiée
        cp ".versioning/$1.v$2" "$1"
        echo "La version $2 du fichier $1 a été restaurée avec succès"
    else
        # Restaurer la dernière version
        cp ".versioning/$1.v$last_version" "$1"
        echo "La dernière version du fichier $1 a été restaurée avec succès"
    fi
}


# main
if test $# -eq 1 && test $1 = "--help" ; then
    usage
    exit 0
elif test $# -eq 0 ; then
    echo "Erreur commande"
    help
    exit 1
else
    case $1 in
        add)
            addCommande $2 $3
            ;;
        rm)
            rmCommande $2
            ;;
        commit|ci)
            commitCommande $2 $3
            ;;
        diff)
            diffCommande $2
            ;;
        checkout|co)
            checkoutCommande $2 $3
            ;;
        *)
            echo "Erreur commande"
            help
            exit 1
            ;;
    esac
fi

# Peut-on ajouter des dossiers? à voir
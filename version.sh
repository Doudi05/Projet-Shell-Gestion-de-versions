#!/bin/dash   

# projet version.sh 
# AKEL Ward , AIACH Rami , TD2/TP2B

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
    echo "Enter ./version.sh --help for more information." >&2
}

# Fonction qui vérifie qu'un argument n’est pas vide, et qu’il est bien sur une seule ligne.
# Si ce n’est pas le cas, affiche un message d’erreur et quitte le programme.
# $1 : le nom de l’argument
checkArgument (){
    if [ -z "$1" ] ; then
        echo "Erreur : l'argument $1 est vide" >&2
        exit 1
    fi

    if [ $(echo "$1" | wc -l) -ne 1 ] ; then
        echo "Erreur : l'argument $1 contient plusieurs lignes" >&2
        exit 1
    fi
}


# Usage : ./version.sh add FILE MESSAGE
# FILE est le nom du fichier à ajouter sous versioning.
# MESSAGE est le message de log associé à la première version du fichier.
# Le fichier doit être ajouté dans le répertoire .versioning du répertoire courant.

addCommande (){
    # Écrire le message de log associé à la première version
    checkArgument "$2"

    # vérifier que le fichier FILE est un fichier ordinaire existant avec la permission de lecture
    if [ ! -f "$1" ] && [ ! -r "$1" ]; then
        echo "Error! $1 is not a regular file or read permission is not granted."
        help
        exit 1
    fi

    # Créer le répertoire .versioning s'il n'existe pas
    if [ ! -d ".versioning" ]; then
        mkdir .versioning
    fi

    # si le fichier existe déjà dans le répertoire .versioning, on renvoie une erreur
    if [ -f ".versioning/$1.1" ]; then
        echo "Error! $1 is already under versioning."
        help
        exit 1
    fi

    #Copier le fichier dans le répertoire .versioning
    cp "$1" ".versioning/$1.1"
    
    echo "$(date -R) '$(echo "$2" | tr -d '[:space:]')'" >> ".versioning/$1.log"

    echo "Added a new file under versioning: '$1'"
}


# Usage : ./version.sh rm FILE
# FILE est le nom du fichier à supprimer sous versioning.

rmCommande (){
    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Demander une confirmation à l'utilisateur
    echo "Are you sure you want to delete $1 from versioning ? (yes/no)"
    read confirmation

    # Vérifier la sensibilité à la casse de la réponse
    if [ "$confirmation" != "yes" ] && [ "$confirmation" != "YES" ]; then
        echo "Nothing done."
        exit 0
    else
        # Supprimer toutes les versions du fichier
        rm .versioning/$1.*

        echo "$1 is not under versioning anymore."

        # Vérifier si le répertoire .versioning est vide et le supprimer le cas échéant
        if [ -z "$(ls -A .versioning)" ]; then
            rm -r .versioning
            echo "The .versioning directory was successfully deleted" 
        fi
    fi
}


# Usage : ./version.sh commit|ci FILE MESSAGE
# FILE est le nom du fichier à sauvegarder sous versioning.
# MESSAGE est le message de log associé à la nouvelle version du fichier.

commitCommande (){
    # Écrire le message de log associé à la première version
    checkArgument "$2"

    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Vérifier si le fichier courant est identique à la dernière version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "Error! $1 is already up to date, nothing to commit."
        exit 1
    fi

    echo "Committed a new version: $(($last_version + 1))"

    # Sauvegarder la nouvelle version
    cp "$1" ".versioning/$1.$((last_version + 1))"
    
    echo "$(date -R) '$(echo "$2" | tr -d '[:space:]')'" >> ".versioning/$1.log"

    echo "The new version of $1 has been committed successfully."
}


# Usage : ./version.sh diff FILE
# FILE est le nom du fichier à comparer.

diffCommande (){
    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Vérifier le numéro de la dernière version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    # Vérifier si le fichier courant est identique à la dernière version
    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "The file $1 has not been modified since the last commit."
        echo "No difference between the current version and the last one."
        exit 0
    else
        # Afficher la différence entre le fichier courant et la dernière version
        diff "$1" ".versioning/$1.$last_version"
    fi
}


# Usage : ./version.sh checkout|co FILE [NUMBER]
# FILE est le nom du fichier à restaurer.
# NUMBER est le numéro de la version à restaurer.

checkoutCommande (){
    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Vérifier le numéro de la dernière version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    # Vérifier si le fichier courant est identique à la dernière version
    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "The file $1 has not been modified since the last commit."
        echo "No difference between the current version and the last one."
        exit 0
    fi

    # Vérifier si le numéro de version est spécifié
    if [ $# -eq 2 ]; then
        # Vérifier si le numéro de version est valide
        if [ $2 -lt 1 ] || [ $2 -gt $last_version ]; then
            echo "Error! the version number must be between 1 and $last_version"
            exit 1
        fi

        # Restaurer la version spécifiée
        cp ".versioning/$1.$2" "$1"
        echo "The version $2 of the file $1 has been restored successfully"
    else
        # Restaurer la dernière version
        cp ".versioning/$1.$last_version" "$1"
        echo "The last version of the file $1 has been restored successfully"
    fi
}


# Usage : ./version.sh log FILE
# FILE est le nom du fichier dont on veut afficher les logs.

logCommande (){
    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi
    
    # Afficher le fichier de log
    nl -s ' : ' ".versioning/$1.log"
}


# Usage : ./version.sh reset FILE [NUMBER]
# FILE est le nom du fichier à restaurer.
# NUMBER est le numéro de la version à restaurer.

resetCommande (){
    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Vérifier le numéro de la dernière version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    # Vérifier si le fichier courant est identique à la dernière version
    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "The file $1 has not been modified since the last commit."
        echo "No difference between the current version and the last one."
        exit 0
    fi
    
    # Vérifier si le numéro de version est spécifié
    if [ $# -eq 2 ]; then
        # Vérifier si le numéro de version est valide
        if [ $2 -lt 1 ] || [ $2 -gt $last_version ]; then
            echo "Error! the version number must be between 1 and $last_version"
            exit 1
        elif [ $2 -eq $last_version ]; then
            echo "Checked out to the latest version, nothing to reset."
            exit 1
        fi

        # Demander une confirmation à l'utilisateur
        echo "Are you sure you want to reset the file $1 to the version $2? (yes/no)"
        read confirmation

        # Vérifier la sensibilité à la casse de la réponse
        if [ "$confirmation" != "yes" ] && [ "$confirmation" != "YES" ]; then
            echo "Nothing done."
            exit 0
        else
            # Restaurer la version spécifiée
            cp ".versioning/$1.$2" "$1"
            echo "The version $2 of the file $1 has been restored successfully"
            
            # Supprimer les versions du numéro strictement supérieur au numéro de version spécifié.
            # les logs des versions supprimées sont également supprimés.
            while [ $last_version -gt $2 ]; do
                rm ".versioning/$1.$last_version"
                sed -i "$last_version d" ".versioning/$1.log"
                last_version=$((last_version-1))
            done
        fi
    else
        # Restaurer la dernière version
        cp ".versioning/$1.$last_version" "$1"
        echo "The last version of the file $1 has been restored successfully"
    fi
}


# Usage : ./version.sh amend FILE [MESSAGE]
# FILE est le nom du fichier à restaurer.
# MESSAGE est le message de log de la version.

amendCommande (){
    # Écrire le message de log associé à la première version
    checkArgument "$2"

    # Vérifier si le fichier existe dans le répertoire .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Erreur : $1 n'est pas sous versioning"
        exit 1
    fi

    # Vérifier le numéro de la dernière version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    # Vérifier si le fichier courant est identique à la dernière version
    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "Le fichier $1 n'a pas été modifié"
        echo "Il n'y a pas de différence entre la dernière version et le fichier courant"
        exit 0
    fi

    # Vérifier si le message de log est spécifié
    if [ $# -eq 2 ]; then
        # Modifier le message de log de la dernière version en gardant la date de la dernière version
        dates="$(date -R) '$(echo "$2" | tr -d '[:space:]')'" >> ".versioning/$1.log"
        sed -i "$last_version s/.*/$dates/" ".versioning/$1.log"
        echo "The log message of the last version of the file $1 has been modified successfully"
    fi

    # Restaurer la dernière version
    cp "$1" ".versioning/$1.$last_version"
    echo "The last version of the file $1 has been restored successfully"
    echo "Last version amended: $last_version"
}






# main
if test $# -eq 1 && test $1 = "--help" ; then
    usage
    exit 0
elif test $# -eq 0 ; then
    help
    exit 1
else
    case $1 in
        add)
            # Vérifier les arguments
            if [ $# -ne 3 ]; then
                echo "Usage : $0 add FILE MESSAGE"
                help
                exit 1
            else
                addCommande $2 $3
            fi
            ;;
        rm)
            # Vérifier les arguments
            if [ $# -ne 2 ]; then
                echo "Usage : $0 rm FILE"
                help
                exit 1
            else
                rmCommande $2
            fi
            ;;
        commit|ci)
            # Vérifier les arguments
            if [ $# -ne 3 ]; then
                echo "Usage : $0 commit FILE MESSAGE"
                help
                exit 1
            else
                commitCommande $2 $3
            fi
            ;;
        diff)
            # Vérifier les arguments
            if [ $# -ne 2 ]; then
                echo "Usage : $0 diff FILE"
                help
                exit 1
            else
                diffCommande $2
            fi
            ;;
        checkout|co)
            # Vérifier les arguments
            if [ $# -lt 2 ] || [ $# -gt 3 ]; then
                echo "Usage : $0 checkout FILE [NUMBER]"
                help
                exit 1
            else
                checkoutCommande $2 $3
            fi
            ;;
        log)
            # Vérifier les arguments
            if [ $# -ne 2 ]; then
                echo "Usage : $0 log FILE"
                help
                exit 1
            else
                logCommande $2
            fi
            ;;
        reset)
            # Vérifier les arguments
            if [ $# -ne 3 ]; then
                echo "Usage : $0 reset FILE [NUMBER]"
                help
                exit 1
            else
                resetCommande $2 $3
            fi
            ;;
        amend)
            # Vérifier les arguments
            if [ $# -ne 3 ]; then
                echo "Usage : $0 amend FILE [MESSAGE]"
                help
                exit 1
            else
                amendCommande $2 $3
            fi
            ;;
        *)
            echo "Error! This command name does not exist: $1"
            help
            exit 1
            ;;
    esac
fi
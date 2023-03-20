#!/bin/dash   

# project version.sh 
# AKEL Ward , AIACH Rami , TD2/TP2B

# the display of the help command
# No parameters expected
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


# display the usage of help command
help (){
    echo "Enter ./version.sh --help for more information." >&2
}

# Fonction check that the argument isn't empty, and within a single line.
# Otherwise, display an error message and exit the program.
# $1 : the tested argument
checkArgument (){
    if [ -z "$1" ] ; then
        echo "Error : the argument $1 is empty" >&2
        exit 1
    fi

    if [ $(echo "$1" | wc -l) -ne 1 ] ; then
        echo "Error : the argument $1 contains multiple lines" >&2
        exit 1
    fi
}


# Usage : ./version.sh add FILE MESSAGE
# FILE is the name of the file to add under versioning.
# MESSAGE is the log message associated with the first version of the file.
# The file must be added in the directory .versioning of the current directory.

addCommande (){
    # Write the log message associated with the first version.
    checkArgument "$2"

    # Check that the file FILE is an existing ordinary file with read permission.
    if [ ! -f "$1" ] && [ ! -r "$1" ]; then
        echo "Error! $1 is not a regular file or read permission is not granted."
        help
        exit 1
    fi

    # Creat directory .versioning if not exist.
    if [ ! -d ".versioning" ]; then
        mkdir .versioning
    fi

    # if file already exist in the directory .versioning, we send an error
    if [ -f ".versioning/$1.1" ]; then
        echo "Error! $1 is already under versioning."
        help
        exit 1
    fi

    # copy the file in  the directory .versioning
    cp "$1" ".versioning/$1.1"
    
    echo "$(date -R) '$(echo "$2" | tr -d '[:space:]')'" >> ".versioning/$1.log"

    echo "Added a new file under versioning: '$1'"
}


# Usage : ./version.sh rm FILE
# FILE is the name of the file to delete under versioning.

rmCommande (){
    # Check if the file exist in the directory .versioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Ask the confirmation of the user
    echo "Are you sure you want to delete $1 from versioning ? (yes/no)"
    read confirmation

    # Check the sensitive cases of the response
    if [ "$confirmation" != "yes" ] && [ "$confirmation" != "YES" ]; then
        echo "Nothing done."
        exit 0
    else
        # Delete all the versions of the file
        rm .versioning/$1.*

        echo "$1 is not under versioning anymore."


	# Check if the .versioning directory is empty and delete it if so
        if [ -z "$(ls -A .versioning)" ]; then
            rm -r .versioning
            echo "The .versioning directory was successfully deleted" 
        fi
    fi
}


# Usage : ./version.sh commit|ci FILE MESSAGE
# FILE is the name of the file to save under versioning.
# MESSAGE is the log message associated with the new version of the file.

commitCommande (){
    # Write the log message associated with the first version
    checkArgument "$2"

    # Check if the file exist in .verioning
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi
    
    # Check if the current file is identical to the latest version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "Error! $1 is already up to date, nothing to commit."
        exit 1
    fi

    echo "Committed a new version: $(($last_version + 1))"

    # Save the new version
    cp "$1" ".versioning/$1.$((last_version + 1))"
    
    echo "$(date -R) '$(echo "$2" | tr -d '[:space:]')'" >> ".versioning/$1.log"

    echo "The new version of $1 has been committed successfully."
}


# Usage : ./version.sh diff FILE
# FILE is the name of the file to compare.

diffCommande (){
    # Check if the file exists in the .versioning directory
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Check the number of last version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    # Check if the current file is identical to the latest version
    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "The file $1 has not been modified since the last commit."
        echo "No difference between the current version and the last one."
        exit 0
    else
        # Display he diffrence between the current file and last file
        diff "$1" ".versioning/$1.$last_version"
    fi
}


# Usage : ./version.sh checkout|co FILE [NUMBER]
# FILE the name of file to restore.
# NUMBER is the number of version to restore

checkoutCommande (){
    # Check if the file exists in the .versioning directory
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Check the number of last version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    # Check if the number of the version is specified
    if [ $# -eq 2 ]; then
        # Check if the number of the version is valide
        if [ $2 -lt 1 ] || [ $2 -gt $last_version ]; then
            echo "Error! the version number must be between 1 and $last_version"
            exit 1
        fi

 	   # Check if the current file is identical to the latest version
        if $(cmp -s "$1" ".versioning/$1.$2"); then
            echo "The file $1 has not been modified since the last commit."
            echo "No difference between the current version and the version $2."
            exit 1
        fi

        # Restore the specified version
        cp ".versioning/$1.$2" "$1"
        echo "The version $2 of the file $1 has been restored successfully"
    else
 	# Check if the current file is identical to the latest version
        if $(cmp -s "$1" ".versioning/$1.$last_version"); then
            echo "The file $1 has not been modified since the last commit."
            echo "No difference between the current version and the last version $last_version."
            exit 1
        fi
        
        # Restore the latest version
        cp ".versioning/$1.$last_version" "$1"
        echo "The last version of the file $1 has been restored successfully"
    fi
}


# Usage : ./version.sh log FILE
# FILE is the name of the file whose logs we want to display.

logCommande (){
    # Check if the file exists in the .versioning directory
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi
    
    # Display log file
    nl -s ' : ' ".versioning/$1.log"
}


# Usage : ./version.sh reset FILE [NUMBER]
# FILE is the name of the file to restore.
# NUMBER is the version number to restore.

resetCommande (){
    # Check if the file exists in the .versioning directory
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error! $1 is not under versioning."
        exit 1
    fi

    # Check the number of last version
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)
    
    # Check if the version number is specified
    if [ $# -eq 2 ]; then
        # Check if the version number is valide
        if [ $2 -lt 1 ] || [ $2 -gt $last_version ]; then
            echo "Error! the version number must be between 1 and $last_version"
            exit 1
        elif [ $2 -eq $last_version ]; then
            # call the checkout command
            checkoutCommande $1 $2
            exit 0
        fi
        
        if $(cmp -s "$1" ".versioning/$1.$2"); then
            echo "The file $1 has not been modified since the last commit."
            echo "No difference between the current version and the version $2."
            exit 1
        fi

        # Ask the users confirmation
        echo "Are you sure you want to reset the file $1 to the version $2? (yes/no)"
        read confirmation

        # Check the sensitive cases of the response
        if [ "$confirmation" != "yes" ] && [ "$confirmation" != "YES" ]; then
            echo "Nothing done."
            exit 0
        else
            # Restore the specified version
            cp ".versioning/$1.$2" "$1"
            echo "The version $2 of the file $1 has been restored successfully"
            
            # Delete the versions of the number strictly greater than the specified version number.
            # logs of deleted versions are also deleted.
            while [ $last_version -gt $2 ]; do
                rm ".versioning/$1.$last_version"
                sed -i "$last_version d" ".versioning/$1.log"
                last_version=$((last_version-1))
            done
        fi
    fi
}


# Usage : ./version.sh amend FILE [MESSAGE]
# FILE is the name of the file to restore.
# MESSAGE is the log message of the version.

amendCommande (){
    # Write the log message associated with the first version
    checkArgument "$2"

    # Check if the file exists in the .versioning directory
    if [ ! -f ".versioning/$1.1" ]; then
        echo "Error : $1 is not under versioning"
        exit 1
    fi

    # Check the latest version number
    last_version=$(ls -1 .versioning | grep "$1." | cut -d '.' -f 3 | sort -n | tail -1)

    # Check if the current file is identical to the latest version
    if $(cmp -s "$1" ".versioning/$1.$last_version"); then
        echo "The file $1 has not been modified"
        echo "ther is no differenece between the last version and the current version"
        exit 0
    fi

    # Check if log message is specified
    if [ $# -eq 2 ]; then
        # Modify the last version log message keeping the date of the last version
        dates="$(date -R) '$(echo "$2" | tr -d '[:space:]')'" >> ".versioning/$1.log"
        sed -i "$last_version s/.*/$dates/" ".versioning/$1.log"
        echo "The log message of the last version of the file $1 has been modified successfully"
    fi

    # Restore the last version
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
            # Check arguments
            if [ $# -ne 3 ]; then
                echo "Usage : $0 add FILE MESSAGE"
                help
                exit 1
            else
                addCommande $2 $3
            fi
            ;;
        rm)
            # Check arguments
            if [ $# -ne 2 ]; then
                echo "Usage : $0 rm FILE"
                help
                exit 1
            else
                rmCommande $2
            fi
            ;;
        commit|ci)
            # Check arguments
            if [ $# -ne 3 ]; then
                echo "Usage : $0 commit FILE MESSAGE"
                help
                exit 1
            else
                commitCommande $2 $3
            fi
            ;;
        diff)
            # Check arguments
            if [ $# -ne 2 ]; then
                echo "Usage : $0 diff FILE"
                help
                exit 1
            else
                diffCommande $2
            fi
            ;;
        checkout|co)
            # Check arguments
            if [ $# -lt 2 ] || [ $# -gt 3 ]; then
                echo "Usage : $0 checkout FILE [NUMBER]"
                help
                exit 1
            else
                checkoutCommande $2 $3
            fi
            ;;
        log)
            # Check arguments
            if [ $# -ne 2 ]; then
                echo "Usage : $0 log FILE"
                help
                exit 1
            else
                logCommande $2
            fi
            ;;
        reset)
            # Check arguments
            if [ $# -ne 3 ]; then
                echo "Usage : $0 reset FILE [NUMBER]"
                help
                exit 1
            else
                resetCommande $2 $3
            fi
            ;;
        amend)
            # Check arguments
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
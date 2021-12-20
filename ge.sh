#!/bin/bash

command=
show_help=false

container="mysql"
name_db="lportal"

only_cache=false
dxp=false

project_path=~/dev/projects/liferay-portal/
wizard_path=~/dev/bundles/master/portal-setup-wizard.properties
me_path=~/dev/projects/liferay-portal/app.server.me.properties

show_basic_usage() {
    printf 'usage lfc [--all] [-h | --help] [--tomcat | -t]\n\t  [--database | -d] [--untracked | -u] <command> [<args>]'
}

show_all_usage() {
    printf 'usage lfc --all [-c | --container] --name\n\t  --wizard-path --me-path --only-cache --project-path --dxp [-h | --help]'
}

show_tomcat_usage() {
    printf 'usage lfc %s [-p | --path] --only-cache --project-path --dxp [-h | --help]' "$command"
}

show_untracked_usage() {
    printf 'usage lfc %s [-p | --path] --dxp [-h | --help]' "$command"
}

show_database_usage() {
    printf 'usage lfc %s [-c | --container] --name [-h | --help]' "$command"
}

show_basic_help() {
    show_basic_usage
    printf '\n\nThese are basic commands used in various situations:\n'
    printf 'all \t\t Run all steps to clean up the Liferay instance.\n'
    printf 'tomcat \t\t Clean up caches in tomcat directory.\n'
    printf 'database \t Clean up the MySQL database instance.\n'
    printf 'untracked \t Clean up untracked files in Liferay project directory.\n\n'
    printf "See 'lfc <command> [-h | --help]' to read about a specific subcommand."
}

show_all_help() {
    show_all_usage
    printf '\n\nThese are optionals commands used in various situations:\n'
    printf 'container \t Indicate a docker container to clean up a MySQL instance.\n'
    printf 'name \t\t Database name to connect it.\n'
    printf "wizard-path \t Path to portal-setup-wizard.properties in bundles\n\t\t configuration directory.\n"
    printf "me-path \t Path to app.server.me.properties in\n\t\t Liferay Portal directory.\n"
    printf "only-cache \t This allow the command only delete cache like data,\n\t\t osgi/state folders in bundles configuration directory.\n"
    printf "project-path \t Path to Liferay Project directory.\n"
    printf "dxp \t Allow command to run the ant setup-profile-dxp."
}

show_database_help() {
    show_database_usage
    printf '\n\nThese are optionals commands used in various situations:\n'
    printf 'container \t Indicate a docker container to clean up a MySQL instance.\n'
    printf 'name \t\t Database name to connect it.\n'
}

show_tomcat_help() {
    show_tomcat_usage
    printf '\n\nThese are optionals commands used in various situations:\n'
    printf 'path \t Path to portal-setup-wizard.properties in bundles\n\t\t configuration directory.\n'
    printf 'only-cache \t This allow the command only delete cache like data,\n\t\t osgi/state folders in bundles configuration directory.\n'
    printf "project-path \t Path to Liferay Project directory.\n"
    printf "dxp \t Allow command to run the ant setup-profile-dxp."
}

show_untracked_help() {
    show_untracked_usage
    printf '\n\nThese are optionals commands used in various situations:\n'
    printf 'path \t Path to portal-setup-wizard.properties in bundles\n\t\t configuration directory.\n'
    printf "dxp \t Allow command to run the ant setup-profile-dxp."
}

run_database() {
    printf 'Starting database clean up'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '\n'

    printf 'Creating SQL file temporary as temp_sql.sql to run it...\n'
    printf 'DROP DATABASE %s; CREATE DATABASE %s;' "$name_db" "$name_db" >temp_sql.sql

    printf 'Running the SQL file in MySQL instance...\n'
    output=$(docker exec -i $container mysql --login-path=local <temp_sql.sql 2>&1)

    if [ $output ]; then
        if [[ $output == *"Warning"* ]]; then
            rm temp_sql.sql

            printf "\nApparently you didn't create a login-path for running MySQL script, try run this before run this script: \n\n"
            printf "First, run this command:\n"
            printf "docker exec -it %s mysql bash -l" "$container"
            printf "\n\nSecond, run this command, already inside the docker instance:\n"
            printf "mysql_config_editor set --login-path=local --host=localhost --user=username --password"
            printf "\n\nThe password that will be asked is the same that you set when create the MySQL instance."
            exit 1
        else
            rm temp_sql.sql

            echo $output
            exit 1
        fi
    fi

    printf 'Removing the temporary SQL file...\n'
    rm temp_sql.sql

    printf 'The database has been successfully cleaned!\n\n\n'
}

run_tomcat() {
    printf 'Starting tomcat clean up'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '\n'

    if [ -f "$wizard_path" ]; then
        dir="$(dirname "$wizard_path")"
        parent_dir="$(dirname "$dir")"
        filename="$(basename "$wizard_path")"

        if [ "$only_cache" = true ]; then
            printf 'Removing cache directories...\n'
            rm -rf "$dir/data $dir/elasticsearch* $dir/osgi/state"

            printf 'The tomcat has been successfully cleaned!\n\n\n'
        else
            printf 'Moving portal-setup-wizard.properties to keep this file...\n'
            mv $wizard_path "$parent_dir/$filename"

            printf 'Removing the bundles directory...\n'
            rm -rf $dir

            printf 'Create a empty bundles directory...\n'
            mkdir $dir

            printf 'Moving portal-setup-wizard.properties to empty directory...\n'
            mv "$parent_dir/$filename" $wizard_path

            printf 'The tomcat has been successfully cleaned!\n\n\n'
        fi
    else
        printf "portal-setup-wizard.properties doesn't exists."
        exit 1
    fi
}

run_untracked() {
    printf 'Starting untracked clean up'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '\n'

    if [ -f "$me_path" ]; then
        dir="$(dirname "$me_path")"
        parent_dir="$(dirname "$dir")"
        filename="$(basename "$me_path")"

        project_path=$dir

        printf 'Moving app.server.me.properties to keep this file...\n'
        mv $me_path "$parent_dir/$filename"

        printf 'Running git clean -dfx to remove untracked files...\n\n'
        git -C $dir clean -dfx

        printf 'Moving app.server.me.properties to your directory...\n'
        mv "$parent_dir/$filename" $me_path

        printf 'The untracked has been successfully cleaned!\n\n\n'
    else
        printf "app.server.me.properties doesn't exists."
        exit 1
    fi
}

run_ant() {
    printf 'Running ant steps'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '.'
    sleep .5
    printf '\n'

    cd $project_path

    printf 'Running ant clean...\n\n'
    ant clean

    if [ "$dxp" = true ]; then
        printf '\n\nRunning ant setup-profile-dxp...\n\n'
        ant setup-profile-dxp
    fi

    printf '\n\nRunning ant all...\n\n'
    ant all

    cd -
}

while :; do
    case $1 in
    --all | -t | --tomcat | -d | --database | -u | --untracked)
        if [ -z "$command" ]; then
            command=$1
        else
            case $command in
            --all)
                show_all_help >&2
                exit
                ;;
            -d | --database)
                show_database_help >&2
                exit
                ;;
            -t | --tomcat)
                show_tomcat_help >&2
                exit
                ;;
            -u | --untracked)
                show_untracked_help >&2
                exit
                ;;
            esac
        fi
        ;;
    -c | --container)
        case $command in
        --all | -d | --database)
            if [[ "$2" && ! "$2" =~ ^- ]]; then
                container=$2
                shift
            else
                printf "ERROR: '%s' requires a string argument.\n" "$1" >&2
                exit 1
            fi
            ;;
        -t | --tomcat)
            show_tomcat_help >&2
            exit
            ;;
        -u | --untracked)
            show_untracked_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    --name)
        case $command in
        --all | -d | --database)
            if [[ "$2" && ! "$2" =~ ^- ]]; then
                name_db=$2
                shift
            else
                printf "ERROR: '%s' requires a string argument.\n" "$command" >&2
                exit 1
            fi
            ;;
        -t | --tomcat)
            show_tomcat_help >&2
            exit
            ;;
        -u | --untracked)
            show_untracked_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    --only-cache)
        case $command in
        --all | -t | --tomcat)
            only-cache=true
            ;;
        -d | --database)
            show_database_help >&2
            exit
            ;;
        -u | --untracked)
            show_untracked_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    --wizard-path)
        case $command in
        --all)
            if [[ "$2" && ! "$2" =~ ^- ]]; then
                wizard_path=$2
                shift
            else
                printf "ERROR: '%s' requires a argument.\n" "$command" >&2
                exit 1
            fi
            ;;
        -d | --database)
            show_database_help >&2
            exit
            ;;
        -t | --tomcat)
            show_tomcat_help >&2
            exit
            ;;
        -u | --untracked)
            show_untracked_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    --me-path)
        case $command in
        --all)
            if [[ "$2" && ! "$2" =~ ^- ]]; then
                me_path=$2
                shift
            else
                printf "ERROR: '%s' requires a argument.\n" "$command" >&2
                exit 1
            fi
            ;;
        -d | --database)
            show_database_help >&2
            exit
            ;;
        -t | --tomcat)
            show_tomcat_help >&2
            exit
            ;;
        -u | --untracked)
            show_untracked_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    -p | --path)
        case $command in
        -t | --tomcat)
            if [[ "$2" && ! "$2" =~ ^- ]]; then
                wizard_path=$2
                shift
            else
                printf "ERROR: '%s' requires a argument.\n" "$command" >&2
                exit 1
            fi
            ;;
        -u | --untracked)
            if [[ "$2" && ! "$2" =~ ^- ]]; then
                me_path=$2
                shift
            else
                printf "ERROR: '%s' requires a argument.\n" "$command" >&2
                exit 1
            fi
            ;;
        -d | --database)
            show_database_help >&2
            exit
            ;;
        --all)
            show_all_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    --project-path)
        case $command in
        --all | -t | --tomcat)
            if [[ "$2" && ! "$2" =~ ^- ]]; then
                project_path=$2
                shift
            else
                printf "ERROR: '%s' requires a argument.\n" "$command" >&2
                exit 1
            fi
            ;;
        -d | --database)
            show_database_help >&2
            exit
            ;;
        -u | --untracked)
            show_untracked_help >&2
            exit
            ;;
        --all)
            show_all_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    --dxp)
        case $command in
        --all | -t | --tomcat | -u | --untracked)
            dxp=true
            ;;
        -d | --database)
            show_database_help >&2
            exit
            ;;
        *)
            show_basic_help >&2
            exit
            ;;
        esac
        ;;
    -h | --help)
        show_help=true
        ;;
    *)
        break
        ;;
    esac

    shift
done

if [ -z "$command" ]; then
    show_basic_help
else
    case $command in
    --all)
        if [ "$show_help" = true ]; then
            show_all_help
        else
            run_database && run_untracked && run_tomcat && run_ant
        fi
        exit
        ;;
    -d | --database)
        if [ "$show_help" = true ]; then
            show_database_help
        else
            run_database
        fi
        exit
        ;;
    -t | --tomcat)
        if [ "$show_help" = true ]; then
            show_tomcat_help
        else
            run_tomcat && run_ant
        fi
        exit
        ;;
    -u | --untracked)
        if [ "$show_help" = true ]; then
            show_untracked_help
        else
            run_untracked && run_ant
        fi
        exit
        ;;
    esac
fi

#!/bin/bash
clean_tomcat(){
	FILE=~/dev/bundles/master/portal-setup-wizard.properties
	if test -f "$FILE"; then
		mv ~/dev/bundles/master/portal-setup-wizard.properties ~/dev/bundles/portal-setup-wizard.properties
		rm -rf ~/dev/bundles/master/
		mkdir ~/dev/bundles/master/
		mv ~/dev/bundles/portal-setup-wizard.properties ~/dev/bundles/master/portal-setup-wizard.properties
	else
		echo "$FILE doesn't exists."
	fi
}

clean_git(){
	FILE=~/dev/projects/liferay-portal/app.server.me.properties
	if test -f "$FILE"; then
		mv ~/dev/projects/liferay-portal/app.server.me.properties ~/dev/projects/app.server.me.properties
		git -C ~/dev/projects/liferay-portal/ clean -dfx
		mv ~/dev/projects/app.server.me.properties ~/dev/projects/liferay-portal/app.server.me.properties
	else
		echo "$FILE doesn't exists."
	fi
}

force_ant(){
	echo "running ant commands"
	cd ~/dev/projects/liferay-portal
	ant clean
	ant all
	cd -
}

clean_db(){
	if [ -z "$2" ]; then
		echo 'DROP DATABASE lportal; CREATE DATABASE lportal;' > temp_sql.sql && \
		docker exec -i $container mysql < temp_sql.sql && \
		rm temp_sql.sql
	fi
}

print_usage(){
 	echo "Missing parameters"
 	echo "Valid Parameters:
	-t -> clean tomcat cache
	-u -> clean cache files in /dev/bundles/
	-d -> clean database 
	**IMPORTANT** if you want to perform all the clean routines or 
	just clean your database, you must inform your docker container. 
	Example: cf -c [container_name], the -c flag is used to inform 
	container name."
	exit 1;
}


while getopts dtuc:* flag
do
	case "${flag}" in
		c) container=${OPTARG} ;;
		t) tomcat='true' ;;
		u) untracked='true' ;;
		d) database='true' ;;
		*) print_usage && exit 1 ;;
	esac
done

#force clean, only specify docker container
if [ -z "$tomcat" ] && [ -z "$database" ] && [ -z "$untracked" ]; then
	if [ ! -z "$container" ]; then
		echo "Running clean all"
		clean_tomcat && clean_db && clean_git && force_ant
	else
		print_usage
	fi
elif [ ! -z "$tomcat" ]; then
	clean_tomcat && force_ant
elif [ ! -z "$database" ]; then
	if [ ! -z "$container" ]; then
		clean_db
	else
		echo "Missing container name 2"
	fi	
elif [ ! -z "$untracked" ]; then
	clean_git && force_ant
fi

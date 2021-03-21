#!/bin/bash

# This script handles the installation of the server and its dependencies,
# including setting up development data. DO NOT RUN ON PROD.

echo "Welcome to the LocalLoop server installation helper!"
echo "===================================================="

read -p "This script will force the installation of development data into the database. \
	For obvious reasons, you *don't* want to do this on prod.\n \
	Did you mean to run this command? (Y/N): " CONFIRM && \
	[[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] || exit 1

DATABASE="sqlite"
if [[ $1 == "-p" ]]; then 
	echo "Using PostgreSQL database..."; 
	DATABASE="postgres"	
fi

echo "Installing Perl dependencies..."
cpanm --installdeps . \
	--with-feature=$DATABASE \
	--with-feature=codepoint-open
echo "Dependency installation complete."

if [[ $1 == "-p" ]]; then 
	echo "This script can only automate deployment for an SQLite database. You \
		will have to sort out your config manually."
else
	echo "Deploying dev database and generating dev data..."	
	./script/deploy_db install -c 'dbi:SQLite:dbname=foodloop.db' 
	./script/pear-local_loop dev_data --force 
	echo "Database set-up complete."
fi

while [ $CONFIRM != [yY] || $CONFIRM != [yY][eE][sS] ]; do
	unset $CONFIRM
	read -p "You must download postcode CSVs manually from \
		\`https://www.doogal.co.uk/PostcodeDownloads.php\`.\n \
		Once you have done so, place them into the `postcode-data/` directory.
		Are you ready to continue? (Y/N): " CONFIRM
done

echo "Importing postcode data..."

./script/pear-local_loop minion worker 
for f in ./postcode-data/*.csv;	do
	./script/pear-local_loop minion job \
		--enqueue 'csv_postcode_import'  \
		--args '[ \"./postcode-data/$f\" ]' 
done

while [ $CONFIRM != [yY] || $CONFIRM != [yY][eE][sS] ]; do
	unset $CONFIRM
	read -p "You must manually import all outcodes that you wish to use using \
		the command \`./script/pear-local_loop codepoint_open --outcodes ⟨ outcode(s) ⟩\`. \
		Are you ready to continue? (Y/N): " CONFIRM
done

./script/pear-local_loop minion job \
	--enqueue entity_postcode_lookup 
echo "Postcode data import complete."

echo "Note: Minion is still running"

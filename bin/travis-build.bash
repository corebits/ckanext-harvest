#!/bin/bash
set -e

echo "This is travis-build.bash..."

echo "Installing the packages that CKAN requires..."
sudo apt-get update -qq
sudo apt-get install postgresql-9.1 solr-jetty libcommons-fileupload-java:amd64=1.2.2-1

echo "Installing CKAN and its Python dependencies..."
git clone https://github.com/ckan/ckan
cd ckan
if [ $CKANVERSION == '2.4' ]
then
    git checkout release-v2.4-latest
elif [ $CKANVERSION == '2.3' ]
then
    git checkout release-v2.3-latest

elif [ $CKANVERSION == '2.2' ]
then
    git checkout release-v2.2-latest
fi
python setup.py develop
pip install -r requirements.txt --allow-all-external
pip install -r dev-requirements.txt --allow-all-external
cd -

echo "Setting up Solr..."
printf "NO_START=0\nJETTY_HOST=127.0.0.1\nJETTY_PORT=8983\nJAVA_HOME=$JAVA_HOME" | sudo tee /etc/default/jetty
sudo cp ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
sudo service jetty restart

echo "Creating the PostgreSQL user and database..."
sudo -u postgres psql -c "CREATE USER ckan_default WITH PASSWORD 'pass';"
sudo -u postgres psql -c 'CREATE DATABASE ckan_test WITH OWNER ckan_default;'

echo "Initialising the database..."
cd ckan
paster db init -c test-core.ini
cd -

echo "Installing ckanext-harvest and its requirements..."
pip install -r pip-requirements.txt --allow-all-external
pip install -r dev-requirements.txt --allow-all-external

python setup.py develop

paster harvester initdb -c ckan/test-core.ini

echo "Moving test.ini into a subdir..."
mkdir subdir
mv test-core.ini subdir

echo "travis-build.bash is done."

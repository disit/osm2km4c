#!/bin/bash

# Define required variables
required_vars=(
    INIDB_HOST INIDB_DATABASE INIDB_USER INIDB_PASSWORD
    DSTDB_HOST DSTDB_DATABASE DSTDB_USER DSTDB_PASSWORD
)

# Flag to track missing variables
missing_vars=()

# Check each variable
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

# Print the result
if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "Error: The following environment variables are not defined:"
    printf ' - %s\n' "${missing_vars[@]}"
    exit 1
fi

echo remove database $DSTDB_DATABASE
psql postgresql://$DSTDB_USER:$DSTDB_PASSWORD@$DSTDB_HOST:${DSTDB_PORT:-5432}/postgres -c "DROP DATABASE IF EXISTS $DSTDB_DATABASE;" ||
  { echo "Error while running psql command: Dropping the db $DSTDB_DATABASE"; exit 1; }

echo create database $DSTDB_DATABASE
psql postgresql://$DSTDB_USER:$DSTDB_PASSWORD@$DSTDB_HOST:${DSTDB_PORT:-5432}/postgres -c "CREATE DATABASE $DSTDB_DATABASE;" ||
  { echo "Error while running psql command: Creating the db $DSTDB_DATABASE"; exit 1; }

echo copy $INIDB_DATABASE to $DSTDB_DATABASE
PGPASSWORD=$INIDB_PASSWORD pg_dump -d $INIDB_DATABASE -h $INIDB_HOST -p ${INIDB_PORT:-5432} -U $INIDB_USER | PGPASSWORD=$DSTDB_PASSWORD psql -h $DSTDB_HOST -p ${DSTDB_PORT:-5432} -U $DSTDB_USER $DSTDB_DATABASE

echo remove some constraints on $DSTDB_DATABASE
PGPASSWORD=$DSTDB_PASSWORD psql -h $DSTDB_HOST -p ${DSTDB_PORT:-5432} -U $DSTDB_USER $DSTDB_DATABASE < remove-constrain.sql

#!/bin/bash

if [ ! "${PWD##*/}" = "build" ]; then
    echo "run me from <srcroot>/build"
    exit 1
fi

cmake ../ -GXcode \
    -DMYSQL_ADD_INCLUDE_PATH=/opt/local/include/mysql5/mysql \
    -DREADLINE_INCLUDE_DIR=/opt/local/include \
    -DREADLINE_LIBRARY=/opt/local/lib/libreadline.dylib \
    -DACE_INCLUDE_DIR=/opt/local/include \
    -DACE_LIBRARY=/opt/local/lib/libACE.dylib \
    -DPREFIX=/opt/trinitycore \
    -DMYSQL_LIBRARY=/opt/local/lib/mysql5/mysql/libmysqlclient_r.dylib

echo "Dropping previous db…"
/opt/local/bin/mysql5 -u root -e "drop database world"
/opt/local/bin/mysql5 -u root -e "drop database characters"
/opt/local/bin/mysql5 -u root -e "drop database auth"

echo "Creating schema…"
/bin/cat ../sql/create/create_mysql.sql | /opt/local/bin/mysql5 -u root
/bin/cat ../sql/base/auth_database.sql | /opt/local/bin/mysql5 -u root auth
/bin/cat ../sql/base/characters_database.sql | /opt/local/bin/mysql5 -u root characters

echo "Importing TDB…"
/bin/cat ../../dbs/TDB_full_434.02_2012_08_30.sql | /opt/local/bin/mysql5 -u root world

echo "Importing updates…"
/usr/bin/find ../sql/updates/world -name "*_world_*" -exec bash -c "echo {}; cat \"{}\" | mysql5 -u root world" \;
/usr/bin/find ../sql/updates/characters -exec bash -c "echo {}; cat \"{}\" | mysql5 -u root characters" \;
/usr/bin/find ../sql/updates/auth -exec bash -c "echo {}; cat \"{}\" | mysql5 -u root auth" \;

xcodebuild -target install

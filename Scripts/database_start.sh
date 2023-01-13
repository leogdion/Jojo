DOCKER_INSTANCE_NAME=jojo-pg
DATABASE_NAME=jojo
USER_NAME=$DATABASE_NAME

docker run --name $DOCKER_INSTANCE_NAME -e POSTGRES_HOST_AUTH_METHOD=trust -d -p 5432:5432 postgres -c log_statement=all
until [ "`docker inspect -f {{.State.Running}} $DOCKER_INSTANCE_NAME`"=="true" ]; do
    sleep 1;
done;
sleep 3;
until [ "`psql -A -t -h localhost -U postgres -c \"SHOW server_version_num;\"`" -gt 120000 ]; do
	sleep 3;
done;

psql -h localhost -U postgres <<EOF
drop database if exists $DATABASE_NAME;
create database $DATABASE_NAME;
create user $DATABASE_NAME;
grant all privileges on database $DATABASE_NAME to $USER_NAME;
EOF

psql -h localhost -U postgres -d $DATABASE_NAME <<EOF
grant all privileges on database $DATABASE_NAME to $USER_NAME;
grant all privileges ON ALL TABLES IN SCHEMA public TO $USER_NAME;
ALTER DATABASE $DATABASE_NAME OWNER TO $USER_NAME;
EOF
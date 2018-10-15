#!/bin/bash
set -e

map_rabbitmq_uid() {
  USERMAP_ORIG_UID=$(id -u rabbitmq)
  USERMAP_ORIG_GID=$(id -g rabbitmq)
  USERMAP_GID=${USERMAP_GID:-${USERMAP_UID:-$USERMAP_ORIG_GID}}
  USERMAP_UID=${USERMAP_UID:-$USERMAP_ORIG_UID}
  if [ "${USERMAP_UID}" != "${USERMAP_ORIG_UID}" ] || [ "${USERMAP_GID}" != "${USERMAP_ORIG_GID}" ]; then
    echo "Adapting uid and gid for rabbitmq:rabbitmq to $USERMAP_UID:$USERMAP_GID"
    groupmod -g "${USERMAP_GID}" rabbitmq
    sed -i -e "s/:${USERMAP_ORIG_UID}:${USERMAP_GID}:/:${USERMAP_UID}:${USERMAP_GID}:/" /etc/passwd
  fi
}

create_socket_dir() {
  mkdir -p /run/rabbitmq
  chmod -R 0755 /run/rabbitmq
  chown -R ${RMQ_USER}:${RMQ_USER} /run/rabbitmq
}

create_data_dir() {
  mkdir -p ${RMQ_DATA_DIR}
  chmod -R 0755 ${RMQ_DATA_DIR}
  chown -R ${RMQ_USER}:${RMQ_USER} ${RMQ_DATA_DIR}
}

create_log_dir() {
  mkdir -p ${RMQ_LOG_DIR}
  chmod -R 0755 ${RMQ_LOG_DIR}
  chown -R ${RMQ_USER}:${RMQ_USER} ${RMQ_LOG_DIR}
}

map_rabbitmq_uid
create_socket_dir
create_data_dir
create_log_dir

# allow arguments to be passed to rabbitmq-server
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
fi

# default behaviour is to launch rabbitmq-server
if [[ -z ${1} ]]; then
  echo "Starting rabbitmq-server..."
  exec start-stop-daemon --start --chuid ${RMQ_USER}:${RMQ_USER} --exec $(which rabbitmq-server) -- \
  ${EXTRA_ARGS}
else
  exec "$@"
fi

#!/bin/bash
export $(cat ${ENV_FILE} | xargs)
exec $@

#!/bin/bash
trap 'echo Deploy failed. An error occured while executing command at `basename $0`:${LINENO}.' ERR
set -e
type gigalixir >/dev/null 2>&1 || { echo >&2 "gigalixir cli is required."; exit 1; }

app='twitter-wall'

branch='master'
if [[ "$(git branch | grep \* | cut -d ' ' -f2)" != "${branch}" ]]; then
    echo "We should be on branch ${branch} to continue. Config file commit is possible."
    exit 2
fi

echo "
=== Set environment variables for ${app} app with content of .env file and others
"
echo -n "This would cause currently running app to restart. Continue (y/n)? "
read answer
if [ "$answer" != "${answer#[Nn]}" ]; then
    exit 3
fi

gigalixir config:set -a $app COOKIE=`cd .. && mix phx.gen.secret`
gigalixir config:set -a $app HOST="tw.ivanrublev.me"
# PORT and SECRET_KEY_BASE are provided by gigalixir
for vr in $(cat ../.env | xargs); do
    gigalixir config:set -a $app "$vr"
done

gigalixir config -a $app


echo "
=== Write buildpack config files with tool versions
"
export $(cat ../.tool-versions | sed -e "s/ /=/g" | xargs)
elixir_bp_cfg='../elixir_buildpack.config'
echo "erlang_version=${erlang}" > $elixir_bp_cfg
echo "elixir_version=${elixir}" >> $elixir_bp_cfg
echo "
${elixir_bp_cfg}:"
cat $elixir_bp_cfg

npm_bp_cfg='../phoenix_static_buildpack.config'
echo "node_version=${nodejs}" > $npm_bp_cfg
echo "
${npm_bp_cfg}:"
cat $npm_bp_cfg

echo "
"
git add $elixir_bp_cfg $npm_bp_cfg
git commit -m "Update buildpack tool version specifications" || true


echo "
=== Deploy ${app} app
"
gigalixir apps:info -a $app
echo -n "This would push the local branch *${branch} to the remote gigalixir. Continue (y/n)? "
read answer
if [ "$answer" != "${answer#[Nn]}" ]; then
    exit 4 
fi

git push gigalixir $branch

gigalixir ps -a $app

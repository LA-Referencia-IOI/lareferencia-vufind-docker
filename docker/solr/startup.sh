#!/bin/sh

# Java security manager is incompatible with AlphaBrowse handler
# (we get an UnsatisfiedLinkError exception without this)
export SOLR_SECURITY_MANAGER_ENABLED="false"

precreate-core authority /configsets/authority
precreate-core biblio /configsets/biblio
precreate-core reserves /configsets/reserves
precreate-core website /configsets/website

exec "$@"

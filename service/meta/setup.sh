#!/bin/sh
set -xe

# Create database if it doesn't already exist
psql -h database -U postgres << EOF
SELECT 'CREATE DATABASE srht_meta'
WHERE NOT EXISTS (SELECT FROM pg_database
                  WHERE datname = 'srht_meta')
\gexec
EOF

# Initialize database and fire up migrations
metasrht-initdb
srht-migrate meta.sr.ht stamp head && metasrht-migrate stamp head

# Create initial admin user if it does not exist
python3 << EOF
from srht.config import cfg
from srht.database import DbSession
from srht.oauth import UserType

from metasrht.auth.base import get_user
from metasrht.auth.builtin import hash_password
from metasrht.types import User

db = DbSession(cfg("meta.sr.ht", "connection-string"))
db.init()

email = "mgmt@local"
username = "mgmt"
password = "highwaytohell"

user = get_user(username)
if user is None:
    user = User(username)
    user.email = email
    user.user_type = UserType["admin"]
    user.password = hash_password(password)
    db.session.add(user)
    db.session.commit()
EOF

# Create OAuth client for git instance
python3 << EOF
from datetime import datetime
from srht.config import cfg
from srht.database import DbSession

from metasrht.types import OAuthClient, OAuthToken
from metasrht.auth.base import get_user

db = DbSession(cfg("meta.sr.ht", "connection-string"))
db.init()

domain = cfg("git.sr.ht", "origin")
username = "mgmt"
client_name = domain
redirect_uri = domain + '/oath/callback'

user = get_user(username)

client_authorizations = (OAuthToken.query
    .join(OAuthToken.client)
    .filter(OAuthClient.preauthorized == True)
    .filter(OAuthClient.client_name == client_name)
    .filter(OAuthToken.user_id == user.id)
    .filter(OAuthToken.expires > datetime.utcnow())
    .filter(OAuthToken.client_id != None)).all()

if not client_authorizations:
    client = OAuthClient(user, client_name, redirect_uri)
    client.preauthorized = True
    client_id = client.client_id
    client_secret = client.gen_client_secret()

    db.session.add(client)
    db.session.commit()

    def replace(filepath, a, b):
        with open(filepath, 'r') as file :
            filedata = file.read()
        filedata = filedata.replace(a, b)
        with open(filepath, 'w') as file:
            file.write(filedata)

    config = '/etc/sr.ht/config.ini'
    replace(config, "\${OAUTH_CLIENT_ID}", client_id)
    replace(config, "\${OAUTH_CLIENT_SECRET}", client_secret)
EOF

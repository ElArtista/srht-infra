#!/bin/sh
set -xe

# Create database if it doesn't already exist
psql -h database -U postgres << EOF
SELECT 'CREATE DATABASE srht_git'
WHERE NOT EXISTS (SELECT FROM pg_database
                  WHERE datname = 'srht_git')
\gexec
EOF

# Initialize database and fire up migrations
gitsrht-initdb
srht-migrate git.sr.ht stamp head && gitsrht-migrate stamp head

# SSH configuration
sed -i '/AuthorizedKeysCommand\s/c\AuthorizedKeysCommand=/usr/bin/gitsrht-dispatch "%u" "%h" "%t" "%k"' /etc/ssh/sshd_config
sed -i '/AuthorizedKeysCommandUser\s/c\AuthorizedKeysCommandUser=root' /etc/ssh/sshd_config
sed -i '/PermitUserEnvironment\s/c\PermitUserEnvironment=SRHT_*' /etc/ssh/sshd_config
ssh-keygen -A

# Git configuration
echo git:* | chpasswd -e
touch /var/log/gitsrht-shell
touch /var/log/gitsrht-update-hook
chown git:git /var/log/gitsrht-shell
chown git:git /var/log/gitsrht-update-hook

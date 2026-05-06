#!/bin/bash
# 1. Update and Install
yum update -y
amazon-linux-extras enable postgresql14
yum install -y postgresql-server

# 2. Initialize and Start
postgresql-setup initdb
systemctl start postgresql
systemctl enable postgresql

# 3. Set the Password (This is what was missing)
# This command tells Postgres to change the password for the 'postgres' user
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'techcorp2026';"

# 4. Configure access (Optional but recommended for the assessment)
# This allows the password to be used for local logins
sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql
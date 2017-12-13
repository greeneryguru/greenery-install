#!/usr/bin/python3

#
# Force reset a user password in the greenery.guru user database
# Usage: python ./reset_user_pw.py <username>
#

import os
import sys
import getpass
sys.path.append( os.environ.get('GREENERY_WEB','/var/www/greenery') )
from greenery import app, db
from greenery.apps.admin.models import User


def main():
    if not sys.argv[1]:
        print("Must provide username")
        print("Usage: reset_user_pw.py <username>")
        sys.exit(1)

    name = sys.argv[1]
    pswd = None
    while True:
        pswd = getpass.getpass('Password: ')
        pswd2 = getpass.getpass('Password again: ')
        if pswd.rstrip() != pswd2.rstrip():
            print("Passwords don't match. Try again.")
        else:
            break

    u = User.query.filter(User.username == name).first()
    if not u:
        sys.stderr.write("Username '%s' not found\n" % name)
        sys.exit(1)

    u.set_password(pswd.rstrip())
    db.session.commit()
    print("Ok")


if __name__ == '__main__':
    main()









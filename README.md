## Multiwan Firewall

Not so much a firewall, but a script to setup iptables and ip routes.

-----

Blah, Blah, Blah.

1. You will need to make changes to the script variables.
2. Move the script to `/etc/network`.
3. `chown root:root` the script
4. `chmod +x` the script
5. Add firewall.service to `/etc/systemd/system/` and `chmod 777` and `chown root:root` the script
6. Then `systemctl enable firewall.service`
7. Best of luck...

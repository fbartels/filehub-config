# Ravpower WD03 enhancements

My very own EnterRouterMode.sh based on the work of [digidem](https://github.com/digidem/filehub-config) and [steve8x8](https://github.com/steve8x8/filehub-config). I will try to merge upstream changes, but focus on mobile file handling and usability.

## Nice to know:
- telnet login is possible after script run. Password for user root is 20080826. (Login is also possible with the admin user and password set from webinterface).
- password for the root user can be changed with ```ChangeRootPassword.sh```.
- all changes to /etc/ have to be made permanent through execution of ```/usr/sbin/etc_tools p```.
- the device has a "hidden" WebDAV service. It can be reached via ```http://10.10.10.254/data```. Credentials are like in the webinterface.

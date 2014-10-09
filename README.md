# s6_gateware repository

This is the source repository for the SERENDIP6 gateware.  It has mlib_devel as
a git submodule.  After cloning this repository, the mlib_devel subdirectoy
will be empty until the mlib_devel submodule is initialized.  You can do this
by running:

```bash
$ git submodule init

$ git submodule update
```

Whenever you pull/merge a new version of this repository, you should verify
whether the mlib_devel version has changed and, if so, update it.  Since
updating an already up-to-date submodule is essentially a no-op, you just need
to follow the pull/merge command with a submodeul update command:

```bash
$ git submodule update
```

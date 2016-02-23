Upgrading PostgreSQL
====================

Here are the steps for upgrading PostgreSQL from version 9.2 (or 9.3 if you are on that) to 9.5 in n easy steps.

1. Dump your current PostgreSQL data
```
pg_dumpall -f everything.sql
```

1. Stop postgres
```
lunchy stop postgres
```
or
```
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.vibes-postgresql.plist
```
or
```
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
```

1. Move your old postgres data directory off to the side
```
cd /usr/local/var
mv postgres postgres-old
```

1. Tell homebrew to prefer the `vibes/software` tap
```
brew tap-pin vibes/software
```

1. Install the new version of postgresql
```
brew install vibes/software/postgresql
```
Make sure to follow the post-install instructions to have postgres start automatically.

1. Install/upgrade postgis if you are working with apps that need it (qrapp is one that needs it). If you have installed qrapp in the past and it's data was still in your database, you will need to do this step in order to reload your data!
```
brew install vibes/software/postgis
```

1. Start postgres up! (remove the `-w` flag if you do not want MacOS to always start it up for you)
```
lunchy start -w postgres
```
or
```
launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
```

1. Reload your data
```
psql -f everything.sql postgres
```

1. Confirm that everything works. Connect to the database and run some queries. Fire up some apps that actually do something to be sure everything is there.

1. Uninstall the old versions of vibes-postgresql and vibes-postgis
```
brew uninstall vibes-postgis
brew uninstall vibes-postgresql
```

1. Delete your old postgres directory (if you want)
```
cd /usr/local/var
rm -r postgres-old
```
You can also delete your `everything.sql` file as well.

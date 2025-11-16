# firefox-password-merger
merges multiple exported firefox password .csv files in smart way

This script was made because password import (at least in Firefox 140.5.0esr) is not smart, and will overwrite newer password with old expired ones.

NO WARRANTY is provided. If it breaks, you get to keep both pieces.

## Usage:
- make sure you have BACKUPS of all your data on all your browsers (i.e. `~/.mozilla/*`)
- make sure you always use good MASTER PASSWORD in your firefox to protect the password database.
- export passwords from each machine / browser / profile  to CSV file 
  (i.e. for Firefox 140.5.0esr in `about:logins` URL click `...` / `Export passwords...`)
- make all exported `*.csv` files available if same directory on same machine
- run `firefox-password-merger export1.csv export2.csv export3.csv > merged_passwords.csv`
- check any warnings outputted to STDERR -- they might result in those entries being lost! If everything is ok, there should be no output in the terminal
- verify if `merged_passwords.csv` looks reasonable
- in target firefox:
  - clear existing passwords via `...` / `Remove all passwords...`
  - import merged password list via `...` / `Import from a file...` and choosing `merged_passwords.csv`
  - check if all passwords work properly. If they do, you can repeat the process in other firefox instances/profiles

- (optional) backup all source and destination .csv files in some archive protected with good password which you will remember and copy it to a safe place
- `wipe *.csv` (`apt install wipe` in Debian) to securely delete all CSV file with plaintext so they cannot be recovered (do it on all machines where they were existing)


## Options:
- just list two or more source .csv files on command line, and redirect output to a targer file,
  e.g. `firefox-password-merger export1.csv export2.csv export3.csv > merged_passwords.csv`
- to be safer, you can set environment variable `DEBUG` to 1 to get information about suspicious duplicate entries which you might want to doublecheck
  e.g. `DEBUG=1 firefox-password-merger export*.csv > merged_passwords.csv`
- there is also `DEBUG=9` if you really need to debug the perl code issues...

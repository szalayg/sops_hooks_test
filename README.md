# SOPS und Git mit Git Hooks

Um das Leben um Verschlüsseln und Entschlüsseln von Git-versionierten Dateien zu erleichtern, eignet sich eine von Git selbst angebotene Methode sehr gut: mit Git Hooks können vor und nach bestimmten Schritten verschiedene Skripte aufrufen. Die sind per default unter `$GIT_VERZEICHNIS\.git\hooks\`mit den Namen `applypatch-msg commit-msg fsmonitor-watchman post-update pre-applypatch pre-commit pre-merge-commit prepare-commit-msg pre-push pre-rebase pre-receive update `

zu finden. An sich sind die nicht in enabled Status, daher heissen die `$DATEI.sample` . Mit dem Entfernern der .sample suffix können die eingeschaltet werden.

```shell
gszalay@localhost:~/sops_hooks_test> ls -l .git/hooks
insgesamt 56
-rwxr-xr-x 1 gszalay users  478 30. Nov 11:19 applypatch-msg.sample
-rwxr-xr-x 1 gszalay users  896 30. Nov 11:19 commit-msg.sample
-rwxr-xr-x 1 gszalay users 4655 30. Nov 11:19 fsmonitor-watchman.sample
-rwxr-xr-x 1 gszalay users  189 30. Nov 11:19 post-update.sample
-rwxr-xr-x 1 gszalay users  424 30. Nov 11:19 pre-applypatch.sample
-rwxr-xr-x 1 gszalay users 1643 30. Nov 11:19 pre-commit.sample
-rwxr-xr-x 1 gszalay users  416 30. Nov 11:19 pre-merge-commit.sample
-rwxr-xr-x 1 gszalay users 1492 30. Nov 11:19 prepare-commit-msg.sample
-rwxr-xr-x 1 gszalay users 1348 30. Nov 11:19 pre-push.sample
-rwxr-xr-x 1 gszalay users 4898 30. Nov 11:19 pre-rebase.sample
-rwxr-xr-x 1 gszalay users  544 30. Nov 11:19 pre-receive.sample
-rwxr-xr-x 1 gszalay users 3635 30. Nov 11:19 update.sample
```

Die hier eingepflegten Skripte werden (falls eingeschaltet) mit den üblichen Git Aktionen automatisch aufgerufen.

In unserem Fall werden leicht angepasste Skripte von Github verwendet: der Inhalt der Repo https://github.com/richardfan1126/sops-githooks entspricht fast 100%-ig unseren Zielen. Die Anpassung bezieht sich auf die age-Keys: die ursprüngliche Idee verwendet GPG-Schlüssel, wir haben und aber für `age` entschieden. Daher wird bei der Entschlüsselung automatisch die erste Zeile in der Datei `~HOME/.config/sops/age/keys.txt` mit public key genommen und verarbeitet. Da lokalen Hooks nicht mit den entfernten Repos synchronisiert werden, speichern wir auch diese Skripte in unserem git-Root Verzeichnis. Bei dieser Methode stehen uns zwei Lösungen zur Verfügung: entweder den Inhalt nach `./.git/hooks/` zu kopieren, oder fit so zu konfigurieren, dass diese Dateien für Hooks verwendet werden. ***Vorsicht, die Schritte sollen in allen unabhängigen Git Repos ausgeführt werden!***

Sollte unsere Git Version höher als 2.9 sein, genügt der Befehl:

```shell
git config core.hooksPath .githooks
```

Sollte er eine frühere Version sein, kann man mit Symlinks umgehen: 

```shell
find .git/hooks -type l -exec rm {} \; && find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;
```

Damit können wir auch unseren Hooks in Git speichern, so dass die bei jedem einsatzbereit sind, und wir doch keine sensitiven Daten mit anderen teilen: keine Datei, die zum Entschlüsseln erforderlich ist, landet damit im Git.

*Als der README geschrieben wird, verwendet SUSE git version 2.26.2, git config sollte ohne weiteres überall funktionieren.*

Eine wichtige Voraussetzung für die Logik ist eine Liste der zu verschlüsselnden Dateien in einer Texdtatei in git Root Verzeichnis: `.secret_files` .


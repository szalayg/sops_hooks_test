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
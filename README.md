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

In unserem Fall werden leicht angepasste Skripte von Github verwendet: der Inhalt der Repo https://github.com/richardfan1126/sops-githooks entspricht fast 100%-ig unseren Zielen. Die Anpassung bezieht sich auf die age-Keys: die ursprüngliche Idee verwendet GPG-Schlüssel, wir haben und aber für `age` entschieden. Daher wird bei der Entschlüsselung automatisch die erste Zeile in der Datei `~HOME/.config/sops/age/keys.txt` mit public key genommen und verarbeitet. Da lokalen Hooks nicht mit den entfernten Repos synchronisiert werden, speichern wir auch diese Skripte in unserem git-Root Verzeichnis. Bei dieser Methode stehen uns zwei Lösungen zur Verfügung: entweder den Inhalt nach `./.git/hooks/` zu kopieren, oder Git so zu konfigurieren, dass diese Dateien für Hooks verwendet werden. 

***Vorsicht, die Schritte sollen in allen unabhängigen Git Repos ausgeführt werden!***

Sollte unsere Git Version höher als 2.9 sein, genügt der Befehl:

```shell
git config core.hooksPath ${HOOKSVERZEICHNIS}
```

Sollte er eine frühere Version sein, kann man mit Symlinks umgehen: 

```shell
find .git/hooks -type l -exec rm {} \; && find ${HOOKSVERZEICHNIS} -type f -exec ln -sf ../../{} .git/hooks/ \;
```

Damit können wir auch unseren Hooks in Git speichern, so dass die bei jedem einsatzbereit sind, und wir doch keine sensitiven Daten mit anderen teilen: keine Datei, die zum Entschlüsseln erforderlich ist, landet damit im Git.

*Als der README geschrieben wird, verwendet SUSE git version 2.26.2, git config sollte ohne weiteres überall funktionieren.*

Eine wichtige Voraussetzung für die Logik ist eine Liste der zu verschlüsselnden Dateien in einer Texdtatei in git Root Verzeichnis: `.secret_files` . Die dürfen sowohl relativen als auch absoluten Pfaden erhalten. Sinnvoll ist es natürlich, die auf den Git Repo zu beschränken. 

Die Datei muss ganz genau allen betroffenen Dateinamen beinhalten, damit die Verschlüsselung gewährleistet ist. In unserem Beispiel etwa so:

```shell
gszalay@localhost:~/sops_hooks_test> more .secret_files ; ls -larth inventories; date
#more .secret_files
inventories/inventory.yaml
inventories/inventory2.yaml
inventories/inventory3.yaml
roles/rke2_agent/templates/config.yaml.j2
roles/rke2_master/templates/config_m0.yaml.j2
roles/rke2_master/templates/config_mx.yaml.j2
roles/rke2_prepare/templates/registries.yaml.j2
#ls -larth inventories
insgesamt 24K
-rw-r--r-- 1 gszalay users  558 30. Nov 14:47 inventory2.yaml
-rw-r--r-- 1 gszalay users 3,7K 30. Nov 14:49 inventory2.enc.yaml
-rw------- 1 gszalay users  580 30. Nov 15:07 inventory.yaml
-rw-r--r-- 1 gszalay users 3,9K 30. Nov 15:08 inventory.enc.yaml
-rw-r--r-- 1 gszalay users  558  2. Dez 15:13 inventory3.yaml
drwxr-xr-x 1 gszalay users  268  2. Dez 15:18 ..
-rw-r--r-- 1 gszalay users 3,7K  2. Dez 15:18 inventory3.enc.yaml
drwxr-xr-x 1 gszalay users  200  2. Dez 15:18 .
#date
Do 2. Dez 15:23:22 CET 2021
gszalay@localhost:~/sops_hooks_test> 
```

Beim Hinzufügen einer neuer Datei muss man darauf achten, dass die der Liste hinzugefügt wird. Die Logik der Skript ist nicht äußerst kompliziert: prüft die Dateinamen, und verschlüsselt die alle in einer Schleife. Fehlt die neue Datei, wird die nicht verschlüsselt.



## Dateien inkludieren und exkludieren

Die Verschlüssleung an sich tut aber noch nichts dafür, dass wir die kritischen Informationen nicht mit Git synchen. In der `.gitignore` Datei müssen wir genau behaupten, was mit anderen geteilt werden kann und was gar nicht. In unseren Fall sieht es wie folgt aus:



```shell
gszalay@localhost:~/sops_hooks_test> more .gitignore 

roles/rke2_agent/templates/config.enc.yaml.j2
roles/rke2_agent/templates/config.yaml.j2
roles/rke2_master/templates/config_m0.enc.yaml.j2
roles/rke2_master/templates/config_m0.yaml.j2
roles/rke2_master/templates/config_mx.enc.yaml.j2
roles/rke2_master/templates/config_mx.yaml.j2
roles/rke2_prepare/templates/registries.enc.yaml.j2
roles/rke2_prepare/templates/registries.yaml.j2
inventories/inventory*.yaml
!inventories/*enc*
```



***Die Auflistung ist aus zwei Hinsichten besonders interessant***

Und man muss die auch beim Hinzufügen neuer Dateien beachten. 

### Ignorierte Dateien und git add

`roles/rke2_master/templates/config_m0.enc.yaml.j2` steht in der .gitignore Datei, wir aber immer wieder mit Git abgeglichen. Wieso?

Mit `git add roles/rke2_master/templates/config_m0.enc.yaml.j2` kann man dafür sorgen, dass explizit ignorierte Dateien doch synchronisiert werden. Mit denen muss man aber vorsichtig umgehen: da die nicht automatisch beim Aufrufen von `git status` angezeigt werden, müssen die einzeln erlaubt werden. Aufwändig und nicht hundertprozentig sicher, da man immer wieder etwas vergessen kann.

In der `.gitignore` kann man aber auch Anti-Patterns definieren: Dateien, die unbeding synchronisiert werden ***müssen***.  Die werden mit `!` am Zeilenanfang gekennzeichnet, im obigen Beispiel:

```shell
!inventories/*enc*
```

Die Reihenfolge der Einträge ist auch wichtig: wenn die inkludierten Dateien einer grundsätzlich exkludierten Pattern entsprechen, müssen die nach der Ignore-Definition angegeben werden, damit Git die als Ausnahme erkennt:



```shell
#Wir möchten keine inventory Datei unverscchlüsselt hochladen
inventories/inventory*.yaml
#Wir wollen aber, dass die verschlüsselten Versionen in demselben Verzeichnis doch synchronisiert sind
!inventories/*enc*
```

Werden neue Dateien angelegt, müssen wir uns also Gedanken machen: sollten die inhaltlich geschützt werden, müssen wir die den entsprechenden Dateien hinzufügen, wenn die noch nicht abgedeckt sind. Wie in diesem Beispiel:

```shell
#Git Status: alles abgeglichen
gszalay@localhost:~/sops_hooks_test> git status
Auf Branch main
Ihr Branch ist auf demselben Stand wie 'origin/main'.

nichts zu committen, Arbeitsverzeichnis unverändert
gszalay@localhost:~/sops_hooks_test> ls inventories
inventory2.enc.yaml  inventory2.yaml  inventory3.enc.yaml  inventory3.yaml  inventory.enc.yaml  inventory.yaml
#Anlegen neuer Datei: eine weitere Kopie der üblichen Dummy-Inventur
gszalay@localhost:~/sops_hooks_test> cp inventories/inventory3.yaml inventories/inventory4.yaml
#Wegen .gitignore wird der nicht angezeigt
gszalay@localhost:~/sops_hooks_test> git status
Auf Branch main
Ihr Branch ist auf demselben Stand wie 'origin/main'.

nichts zu committen, Arbeitsverzeichnis unverändert
#Wir stellen sicher, dass die verschlüsselt wird
gszalay@localhost:~/sops_hooks_test> echo inventories/inventory4.yaml | tee -a .secret_files 
inventories/inventory4.yaml
#Git sieht jetzt eine Änderung
gszalay@localhost:~/sops_hooks_test> git status
Auf Branch main
Ihr Branch ist auf demselben Stand wie 'origin/main'.

Änderungen, die nicht zum Commit vorgemerkt sind:
  (benutzen Sie "git add <Datei>...", um die Änderungen zum Commit vorzumerken)
  (benutzen Sie "git restore <Datei>...", um die Änderungen im Arbeitsverzeichnis zu verwerfen)
        geändert:       .secret_files

keine Änderungen zum Commit vorgemerkt (benutzen Sie "git add" und/oder "git commit -a")
#Git commit
gszalay@localhost:~/sops_hooks_test> git commit -a -m "Check new file"
inventories/inventory4.yaml modified, please commit again
#Hooks haben verschlüsselt
gszalay@localhost:~/sops_hooks_test> git status
Auf Branch main
Ihr Branch ist auf demselben Stand wie 'origin/main'.

Änderungen, die nicht zum Commit vorgemerkt sind:
  (benutzen Sie "git add <Datei>...", um die Änderungen zum Commit vorzumerken)
  (benutzen Sie "git restore <Datei>...", um die Änderungen im Arbeitsverzeichnis zu verwerfen)
        geändert:       .secret_files

Unversionierte Dateien:
  (benutzen Sie "git add <Datei>...", um die Änderungen zum Commit vorzumerken)
  #Hier ist unsere verschlüsselte Datei
        inventories/inventory4.enc.yaml

keine Änderungen zum Commit vorgemerkt (benutzen Sie "git add" und/oder "git commit -a")
#Wieder Commit
gszalay@localhost:~/sops_hooks_test> git commit -a -m "Check new file"
[main abf9fd3] Check new file
 1 file changed, 1 insertion(+)
#Git push
gszalay@localhost:~/sops_hooks_test> git push
Objekte aufzählen: 5, Fertig.
Zähle Objekte: 100% (5/5), Fertig.
Komprimiere Objekte: 100% (3/3), Fertig.
Schreibe Objekte: 100% (3/3), 300 Bytes | 300.00 KiB/s, Fertig.
Gesamt 3 (Delta 2), Wiederverwendet 0 (Delta 0), Pack wiederverwendet 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To github.com:szalayg/sops_hooks_test.git
   3967df6..abf9fd3  main -> main
gszalay@localhost:~/sops_hooks_test> git status
Auf Branch main
Ihr Branch ist auf demselben Stand wie 'origin/main'.

Änderungen, die nicht zum Commit vorgemerkt sind:
  (benutzen Sie "git add <Datei>...", um die Änderungen zum Commit vorzumerken)
  (benutzen Sie "git restore <Datei>...", um die Änderungen im Arbeitsverzeichnis zu verwerfen)
        geändert:       README.md

Unversionierte Dateien:
  (benutzen Sie "git add <Datei>...", um die Änderungen zum Commit vorzumerken)
        inventories/inventory4.enc.yaml

keine Änderungen zum Commit vorgemerkt (benutzen Sie "git add" und/oder "git commit -a")
gszalay@localhost:~/sops_hooks_test> git commit -a -m "Add new inventory"
[main b434356] Add new inventory
 1 file changed, 69 insertions(+)
#Prüfe die Änderungen
gszalay@localhost:~/sops_hooks_test> git status
Auf Branch main
Ihr Branch ist 1 Commit vor 'origin/main'.
  (benutzen Sie "git push", um lokale Commits zu publizieren)

Unversionierte Dateien:
  (benutzen Sie "git add <Datei>...", um die Änderungen zum Commit vorzumerken)
        inventories/inventory4.enc.yaml

nichts zum Commit vorgemerkt, aber es gibt unversionierte Dateien
(benutzen Sie "git add" zum Versionieren)
#Neue Inventory wird hinzugefügt
gszalay@localhost:~/sops_hooks_test> git add *
gszalay@localhost:~/sops_hooks_test> git commit -a -m "Add new inventory"
[main 625ce96] Add new inventory
 1 file changed, 58 insertions(+)
 create mode 100644 inventories/inventory4.enc.yaml
#Wieder Push
gszalay@localhost:~/sops_hooks_test> git push
Objekte aufzählen: 10, Fertig.
Zähle Objekte: 100% (10/10), Fertig.
Komprimiere Objekte: 100% (7/7), Fertig.
Schreibe Objekte: 100% (7/7), 3.46 KiB | 885.00 KiB/s, Fertig.
Gesamt 7 (Delta 4), Wiederverwendet 0 (Delta 0), Pack wiederverwendet 0
remote: Resolving deltas: 100% (4/4), completed with 3 local objects.
To github.com:szalayg/sops_hooks_test.git
   abf9fd3..625ce96  main -> main
#Jetzt sind wir fertig  
gszalay@localhost:~/sops_hooks_test> 

```


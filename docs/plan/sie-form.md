# Prüfliste Sie-Form (Plan 0.8 Nr. 15)

Stand 22.11.2026, Halt nach D7. **Vorschlag, noch nicht freigegeben und nicht umgesetzt.** Freigabe
durch den Maintainer vor G1, Umsetzung danach in `shell/translations/poexports/de.json`.

Die Oberfläche duzt (`CLAUDE.md`). Im deutschen Katalog des Ursprungs siezen 103 Übersetzungen
(Suche nach `Sie`, `Ihr`, `Ihre`, `Ihren`, `Ihrem`, `Ihrer`, `Ihres`, `Ihnen` als ganzes Wort in
den Werten). Diese Liste nennt je Eintrag den Schlüssel (englischer Quelltext), den heutigen Text
und den Vorschlag in Du-Form und Schweizer Schreibweise. Zeilenumbrüche im Text stehen als `\n`.

Was der Vorschlag nebenbei ändert, je am Eintrag vermerkt:

- Tippfehler des Katalogs (Nr. 23, 75, 88) und zwei Übersetzungen, die den Sinn verfehlen (Nr. 39, 61).
- Anführungszeichen einheitlich «…» statt `"…"`, `'…'` und `„…“`.
- Fachbegriffe bleiben, wie sie der Katalog sonst führt (Display, Widget, Popout, Launcher, Greeter,
  Arbeitsbereich); sie sind nicht Gegenstand dieser Liste.

Die zweite Liste, die 42 Texte ohne deutsche Übersetzung, steht in
`docs/plan/uebersetzung-luecken.md`.

## Liste

**1** `%1 is running and will create duplicate Bluetooth players. Disable it with: %2`
- heute: %1 wird gerade ausgeführt und führt dazu, dass doppelte Bluetooth-Player erstellt werden. Deaktivieren Sie es mit: %2
- neu: %1 läuft und erzeugt doppelte Bluetooth-Player. Deaktiviere es mit: %2

**2** `%1 keeps your desktop running. Ending it will likely break your session. If it misbehaves, restarting it is the safer fix.`
- heute: %1 hält Ihren Desktop am Laufen. Das Beenden wird wahrscheinlich Ihre Sitzung unterbrechen. Sollte es nicht richtig funktionieren, ist ein Neustart die sicherere Lösung.
- neu: %1 hält deinen Desktop am Laufen. Das Beenden wird deine Sitzung wahrscheinlich unterbrechen. Sollte es nicht richtig funktionieren, ist ein Neustart die sicherere Lösung.

**3** `%1 will be removed from your system.`
- heute: %1 wird aus Ihrem System entfernt.
- neu: %1 wird aus deinem System entfernt.

**4** `Also runs the templates in your %1`
- heute: Führt auch die Vorlagen in Ihrem %1 aus
- neu: Führt auch die Vorlagen in deinem %1 aus

**5** `Are you sure you want to kill session "%1"?`
- heute: Sind Sie sicher, dass Sie die Sitzung "%1" beenden wollen?
- neu: Willst du die Sitzung «%1» wirklich beenden?

**6** `Authentication changes need sudo. Opening terminal so you can use password or fingerprint.`
- heute: Authentifizierungsänderungen erfordern Sudo-Rechte. Ein Terminal wird geöffnet, damit Sie das Passwort oder Ihren Fingerabdruck verwenden können.
- neu: Änderungen an der Authentifizierung erfordern sudo. Ein Terminal wird geöffnet, damit du Passwort oder Fingerabdruck verwenden kannst.

**7** `Battery has charged to your set limit of %1%`
- heute: Akku ist bis zu dem von Ihnen festgelegten Limit von %1% aufgeladen
- neu: Akku ist bis zu deinem festgelegten Limit von %1% aufgeladen

**8** `Battery is at %1% - Connect charger immediately!`
- heute: Akkustand beträgt %1% - Schliessen Sie das Ladegerät sofort an!
- neu: Akkustand beträgt %1% – schliess das Ladegerät sofort an!

**9** `Battery is at %1% - Consider charging soon`
- heute: Akkustand beträgt %1% - Denken Sie darüber nach, bald aufzuladen
- neu: Akkustand beträgt %1% – lade bald auf

**10** `Bind the %1 IPC action in your compositor config.`
- heute: Binden Sie die %1 IPC-Aktion in Ihrer Compositor-Konfiguration.
- neu: Binde die IPC-Aktion %1 in deiner Compositor-Konfiguration.

**11** `Boot entry changed. Remove it and add it again.`
- heute: Booteintrag geändert. Entfernen Sie ihn und fügen Sie ihn erneut hinzu.
- neu: Booteintrag geändert. Entferne ihn und füge ihn erneut hinzu.

**12** `Check your custom command in Settings → Dock → Trash.`
- heute: Überprüfen Sie Ihren benutzerdefinierten Befehl unter Einstellungen → Dock → Papierkorb.
- neu: Überprüfe deinen benutzerdefinierten Befehl unter Einstellungen → Dock → Papierkorb.

**13** `Choose a clear area of the background. Drag the clock to place it yourself.`
- heute: Wählen Sie einen freien Bereich des Hintergrunds. Ziehen Sie die Uhr, um sie selbst zu platzieren.
- neu: Wähle einen freien Bereich des Hintergrunds. Zieh die Uhr, um sie selbst zu platzieren.

**14** `Choose what middle-clicking empty bar space does`
- heute: Wählen Sie, was Mittelklicken auf einen leeren Bereich der Leiste bewirkt
- neu: Wähle, was ein Mittelklick auf einen leeren Bereich der Leiste bewirkt

**15** `Choose what right-clicking empty bar space does`
- heute: Wählen Sie, was Rechtsklicken auf einen leeren Bereich der Leiste bewirkt
- neu: Wähle, was ein Rechtsklick auf einen leeren Bereich der Leiste bewirkt

**16** `Choose which displays show this widget`
- heute: Wählen Sie, welche Displays dieses Widget zeigen
- neu: Wähle, welche Displays dieses Widget zeigen

**17** `Click 'Setup' to create %1 and add include to your compositor config.`
- heute: Klicken Sie auf 'Einrichtung', um %1 zu erstellen und das Include zu Ihrer Compositor-Konfiguration hinzuzufügen.
- neu: Klick auf «Einrichtung», um %1 zu erstellen und das Include zu deiner Compositor-Konfiguration hinzuzufügen.

**18** `Click Import to add a %1 or %2 file`
- heute: Klicken Sie auf Importieren, um eine %1- oder %2-Datei hinzuzufügen
- neu: Klick auf «Importieren», um eine %1- oder %2-Datei hinzuzufügen

**19** `Click the icon to mute`
- heute: Klicken Sie auf das Icon zum Stummschalten
- neu: Klick auf das Icon zum Stummschalten

**20** `Comma-separated list of layout names. Leave empty to use the system keyboard settings.`
- heute: Durch Komma getrennte Liste von Layoutnamen. Lassen Sie das Feld leer, um die Tastatureinstellungen des Systems zu verwenden.
- neu: Durch Komma getrennte Liste von Layoutnamen. Lass das Feld leer, um die Tastatureinstellungen des Systems zu verwenden.

**21** `Configure one in Settings → Dock → Trash.`
- heute: Konfigurieren Sie einen unter Einstellungen → Dock → Papierkorb.
- neu: Konfiguriere einen unter Einstellungen → Dock → Papierkorb.

**22** `Custom builds the palette from a color you pick`
- heute: Bildet die Palette benutzerdefiniert aus einer von Ihnen gewählten Farbe
- neu: «Benutzerdefiniert» bildet die Palette aus einer Farbe, die du wählst

**23** `Alpe Settings writes Lua keybinds. Add the Alpe include so edits apply.`
- heute: Alpe-Einstellungen schreibt Lua-Tastenkombinationen. Fügen Sie den Alpe-Include hinzu, damit Bearbeitungen angwendet werden.
- neu: Die Alpe-Einstellungen schreiben Lua-Tastenkombinationen. Füge das Alpe-Include hinzu, damit Änderungen angewendet werden.
- nebenbei: Tippfehler «angwendet»; «das Include» wie in Nr. 17.

**24** `Drag a widget by its handle here to reorder it or drop it into another group`
- heute: Ziehen Sie ein Widget an seinem Handle hierher, um es neu zu ordnen, oder legen Sie es in einer anderen Gruppe ab
- neu: Zieh ein Widget an seinem Griff hierher, um es neu zu ordnen, oder leg es in einer anderen Gruppe ab
- nebenbei: «Griff» statt «Handle».

**25** `Drag groups above the clock to sit left of it, below to sit right. Click the eye to hide a group.`
- heute: Ziehen Sie Gruppen über die Uhr, um sie links davon zu platzieren, oder darunter, um sie rechts davon zu platzieren. Klicken Sie auf das Auge, um eine Gruppe auszublenden.
- neu: Zieh Gruppen über die Uhr, um sie links davon zu platzieren, oder darunter, um sie rechts davon zu platzieren. Klick auf das Auge, um eine Gruppe auszublenden.

**26** `Drag small tiles in to group them`
- heute: Ziehen Sie kleine Kacheln hinein, um diese zu gruppieren
- neu: Zieh kleine Kacheln hinein, um sie zu gruppieren

**27** `Drag the handle to reorder. Tap a widget for its settings, use the switch to hide it without changing spacing, or X to remove it.`
- heute: Ziehen Sie zum Neuordnen das Handle. Tippen Sie ein Widget für dessen Einstellungen an. Verwenden Sie den Schalter, um es auszublenden, ohne den Abstand zu verändern, oder das X, um es zu entfernen.
- neu: Zieh am Griff, um neu zu ordnen. Tippe ein Widget für dessen Einstellungen an. Verwende den Schalter, um es auszublenden, ohne den Abstand zu verändern, oder das X, um es zu entfernen.
- nebenbei: «Griff» statt «Handle».

**28** `Drop your override for %1 so the Alpe default action re-applies?`
- heute: Ihre Ausserkraftsetzung für %1 aufheben, damit die Alpe-Standardaktion wieder angewendet wird?
- neu: Deine Überschreibung für %1 aufheben, damit die Alpe-Standardaktion wieder gilt?

**29** `Enable Wi-Fi before starting the hotspot.`
- heute: Aktivieren Sie WLAN, bevor Sie den Hotspot starten.
- neu: Aktiviere WLAN, bevor du den Hotspot startest.

**30** `Enter a new name for this workspace`
- heute: Geben Sie einen neuen Namen für diesen Arbeitsbereich ein
- neu: Gib einen neuen Namen für diesen Arbeitsbereich ein

**31** `Enter this passkey on %1`
- heute: Geben Sie diesen Passkey bei %1 ein
- neu: Gib diesen Passkey auf %1 ein

**32** `Every output and input of this sound card turns off until you enable it again`
- heute: Jeder Aus- und Eingang dieser Soundkarte wird ausgeschaltet, bis Sie sie wieder aktivieren
- neu: Jeder Aus- und Eingang dieser Soundkarte wird ausgeschaltet, bis du sie wieder aktivierst

**33** `Fingerprint not recognized (%1/%2). Please try again or use password.`
- heute: Fingerabdruck nicht erkannt (%1/%2). Bitte versuchen Sie es erneut oder verwenden Sie das Passwort.
- neu: Fingerabdruck nicht erkannt (%1/%2). Versuch es erneut oder verwende das Passwort.

**34** `Fingerprint reader detected, but no prints are enrolled yet. You can enable this now and enroll later.`
- heute: Fingerabdruckleser erkannt, aber es sind noch keine Abdrücke registriert. Sie können dies jetzt aktivieren und später registrieren.
- neu: Fingerabdruckleser erkannt, aber es sind noch keine Abdrücke registriert. Du kannst das jetzt aktivieren und die Abdrücke später registrieren.

**35** `Generate baseline GTK3/4, QT5/QT6, or qtengine configurations to follow Alpe colors (only qt6ct requires qt6ct-kde). Only needed once.<br /><br />It is recommended to configure %1 prior to applying GTK themes.`
- heute: Generieren Sie Baseline-Konfigurationen für GTK3/4, QT5/QT6 oder qtengine, um den Alpe-Farben zu folgen (nur qt6ct benötigt qt6ct-kde). Nur einmal erforderlich.<br /><br />Es wird empfohlen, %1 zu konfigurieren, bevor GTK-Themes angewendet werden.
- neu: Erzeugt Grundkonfigurationen für GTK3/4, QT5/QT6 oder qtengine, die den Alpe-Farben folgen (nur qt6ct benötigt qt6ct-kde). Nur einmal erforderlich.<br /><br />Es wird empfohlen, %1 zu konfigurieren, bevor GTK-Themes angewendet werden.

**36** `HDR mode is experimental. Verify your monitor supports HDR before enabling.`
- heute: HDR-Modus ist experimentell. Verifizieren Sie vor der Aktivierung, dass Ihr Monitor HDR unterstützt.
- neu: Der HDR-Modus ist experimentell. Prüfe vor dem Aktivieren, ob dein Monitor HDR unterstützt.

**37** `Higher providers take priority. Turn all off to use local lyrics only.`
- heute: Anbieter mit höherer Priorität haben Vorrang. Schalten Sie alle aus, um nur lokale Songtexte zu verwenden.
- neu: Anbieter weiter oben haben Vorrang. Schalte alle aus, um nur lokale Songtexte zu verwenden.

**38** `Hold Ctrl, Alt or Super and press a key. Esc cancels.`
- heute: Halten Sie Strg-, Alt oder Super gedrückt und drücken Sie eine Taste. Mit Esc brechen Sie den Vorgang ab.
- neu: Halte Ctrl, Alt oder Super gedrückt und drück eine Taste. Esc bricht ab.
- nebenbei: «Ctrl» statt «Strg» (Schweizer Tastatur). Der Katalog führt sonst «Strg»; siehe Frage 1.

**39** `Hybrid peeks the current compact face on hover. Click pins a destination so it stays open`
- heute: „Hybrid“ gibt beim Darüberfahren einen Blick auf die aktuelle, kompakte Fläche. Klicken Sie auf Pins eines Ziels, damit es geöffnet bleibt
- neu: «Hybrid» zeigt beim Darüberfahren kurz die aktuelle kompakte Ansicht. Ein Klick heftet ein Ziel an, damit es geöffnet bleibt
- nebenbei: Sinn berichtigt (der Klick heftet an; es gibt keine «Pins eines Ziels»).

**40** `IP sharing setup failed. Check that %1 is installed.`
- heute: Einrichtung der IP-Freigabe fehlgeschlagen. Überprüfen Sie, ob %1 installiert ist.
- neu: Einrichtung der IP-Freigabe fehlgeschlagen. Überprüfe, ob %1 installiert ist.

**41** `If autostart app icons don't appear in the system tray, generate a systemd override to ensure Alpe starts before autostart apps`
- heute: Wenn Autostart-App-Icons nicht im System-Tray erscheinen, generieren Sie einen Systemd-Override, um sicherzustellen, dass Alpe vor den Autostart-Apps startet
- neu: Wenn Icons von Autostart-Apps nicht im System-Tray erscheinen, erzeuge einen systemd-Override, damit Alpe vor den Autostart-Apps startet

**42** `Ignored packages only apply to the built-in updater. Your custom command controls its own exclusions.`
- heute: Ignorierte Pakete gelten nur für den integrierten Updater. Ihr benutzerdefinierter Befehl steuert seine eigenen Ausschlüsse.
- neu: Ignorierte Pakete gelten nur für den integrierten Updater. Dein benutzerdefinierter Befehl steuert seine eigenen Ausschlüsse.

**43** `Insert your security key...`
- heute: Stecken Sie Ihren Sicherheitsschlüssel ein ...
- neu: Steck deinen Sicherheitsschlüssel ein …

**44** `Install the %1 package for dynamic theming`
- heute: Installieren Sie das Paket %1 für dynamisches Theming
- neu: Installiere das Paket %1 für dynamisches Theming

**45** `It runs in a terminal; restart it from there.`
- heute: Es wird in einem Terminal ausgeführt; starten Sie es von dort aus neu.
- neu: Es läuft in einem Terminal; starte es von dort aus neu.

**46** `Maximum fingerprint attempts reached. Please use password.`
- heute: Maximale Anzahl an Fingerabdruckversuchen erreicht. Bitte verwenden Sie das Passwort.
- neu: Maximale Anzahl an Fingerabdruckversuchen erreicht. Verwende das Passwort.

**47** `No apps muted. Right-click a notification and choose "Mute popups" to add one here.`
- heute: Keine Apps stummgeschaltet. Klicken Sie mit der rechten Maustaste auf eine Benachrichtigung und wählen Sie "Popups stummschalten", um hier eine hinzuzufügen.
- neu: Keine Apps stummgeschaltet. Klick mit der rechten Maustaste auf eine Benachrichtigung und wähle «Popups stummschalten», um hier eine hinzuzufügen.

**48** `No display profiles found. Create them in Settings > Displays.`
- heute: Keine Display-Profile gefunden. Erstellen Sie diese unter Einstellungen > Displays.
- neu: Keine Display-Profile gefunden. Erstelle sie unter Einstellungen → Displays.

**49** `No packages ignored. Add one here or hover an update in the popout and click the hide button.`
- heute: Keine Pakete ignoriert. Fügen Sie hier eines hinzu oder fahren Sie im Popout über eine Aktualisierung und klicken Sie auf die Schaltfläche Ausblenden.
- neu: Keine Pakete ignoriert. Füge hier eines hinzu oder fahr im Popout über eine Aktualisierung und klick auf die Schaltfläche «Ausblenden».

**50** `No palettes configured. Use + to add one.`
- heute: Keine Paletten konfiguriert. Verwenden Sie +, um eine hinzuzufügen.
- neu: Keine Paletten konfiguriert. Füge mit + eine hinzu.

**51** `No widgets added. Click "Add widget" to get started.`
- heute: Keine Widgets hinzugefügt. Klicken Sie auf "Widget hinzufügen", um zu beginnen.
- neu: Keine Widgets hinzugefügt. Klick auf «Widget hinzufügen», um zu beginnen.

**52** `No widgets match your search`
- heute: Keine Widgets, die mit Ihrer Suche übereinstimmen
- neu: Keine Widgets passen zu deiner Suche

**53** `Not available - install or configure %1`
- heute: Nicht verfügbar - installieren oder konfigurieren Sie %1
- neu: Nicht verfügbar – installiere oder konfiguriere %1

**54** `Only continue if you recognize this server certificate fingerprint.`
- heute: Fahren Sie nur fort, wenn Sie diesen Fingerabdruck des Serverzertifikats erkennen.
- neu: Fahr nur fort, wenn du diesen Fingerabdruck des Serverzertifikats kennst.

**55** `Pick a different file manager in Settings → Dock → Trash.`
- heute: Wählen Sie einen anderen Dateimanager aus unter Einstellungen → Dock → Papierkorb.
- neu: Wähle einen anderen Dateimanager unter Einstellungen → Dock → Papierkorb.

**56** `Pick an app from the list above or the dashboard tab`
- heute: Wählen Sie eine App aus der obigen Liste oder dem Dashboard-Tab
- neu: Wähle eine App aus der Liste oben oder aus dem Dashboard-Tab

**57** `Pick how long to pause notifications`
- heute: Wählen Sie aus, wie lange Benachrichtigungen pausiert werden sollen
- neu: Wähle, wie lange Benachrichtigungen pausiert werden

**58** `Pick how long to stay awake`
- heute: Wählen Sie aus, wie lange wach geblieben werden soll
- neu: Wähle, wie lange der Rechner wach bleibt

**59** `Place plugin directories here. Each plugin should have a %1 manifest file.`
- heute: Platzieren Sie hier Plugin-Verzeichnisse. Jedes Plugin sollte eine %1-Manifestdatei haben.
- neu: Leg hier Plugin-Verzeichnisse ab. Jedes Plugin braucht eine Manifestdatei %1.

**60** `Please write a name for your new %1 session`
- heute: Bitte schreiben Sie einen Namen für Ihre neue %1-Sitzung
- neu: Gib einen Namen für deine neue %1-Sitzung ein

**61** `Prefix a tag with negative: to match windows without it.`
- heute: Fügen Sie einem Tag 'negativ' als Präfix hinzu, um Fenster ohne dieses Wort zu finden.
- neu: Stell einem Tag negative: voran, um Fenster ohne dieses Tag zu treffen.
- nebenbei: Sinn berichtigt (das Präfix heisst wörtlich `negative:` und wird nicht übersetzt).

**62** `Press Ctrl+N or click 'New Session' to create one`
- heute: Drücken Sie Strg+N oder klicken Sie auf 'Neue Sitzung', um eine zu erstellen
- neu: Drück Ctrl+N oder klick auf «Neue Sitzung», um eine zu erstellen
- nebenbei: «Ctrl» statt «Strg»; siehe Frage 1.

**63** `Press Enter and the audio system will restart to apply the change`
- heute: Drücken Sie die Eingabetaste, um das Audiosystem neu zu starten und die Änderungen anzuwenden
- neu: Drück die Eingabetaste; das Audiosystem startet neu und wendet die Änderung an

**64** `Profile image is too large. Please use a smaller image.`
- heute: Profilbild ist zu gross. Bitte verwenden Sie ein kleineres Bild.
- neu: Das Profilbild ist zu gross. Verwende ein kleineres Bild.

**65** `Re-enter the password before saving.`
- heute: Geben Sie das Passwort vor dem Speichern erneut ein.
- neu: Gib das Passwort vor dem Speichern erneut ein.

**66** `Replace a displayed layout label with custom text, e.g. "am-phonetic-alt" → "am"`
- heute: Ersetzen Sie ein angezeigtes Layout-Label durch benutzerdefinierten Text, bspw. „am-phonetic-alt“ → „am“
- neu: Ersetzt eine angezeigte Layout-Bezeichnung durch eigenen Text, z. B. «am-phonetic-alt» → «am»

**67** `Right-click a notification and choose "Allow in Do Not Disturb" to add an app`
- heute: Klicken Sie mit der rechten Maustaste auf eine Benachrichtigung und wählen Sie "In 'Bitte nicht stören' erlauben", um eine App hinzuzufügen
- neu: Klick mit der rechten Maustaste auf eine Benachrichtigung und wähle «In ‹Bitte nicht stören› erlauben», um eine App hinzuzufügen

**68** `Right-click an app in the launcher and choose 'Edit App'`
- heute: Klicken Sie mit der rechten Maustaste auf eine App im Launcher und wählen Sie 'App bearbeiten'
- neu: Klick mit der rechten Maustaste auf eine App im Launcher und wähle «App bearbeiten»

**69** `Right-click an app in the launcher and choose 'Hide App'`
- heute: Klicken Sie mit der rechten Maustaste auf eine App im Launcher und wählen Sie 'App ausblenden'
- neu: Klick mit der rechten Maustaste auf eine App im Launcher und wähle «App ausblenden»

**70** `Rules found in your compositor config. These are read-only here, use Convert to Alpe to make an editable copy.`
- heute: In Ihrer Compositor-Konfiguration gefundene Regeln. Diese sind hier schreibgeschützt. Verwenden Sie „In Alpe konvertieren“, um eine editierbare Kopie anzulegen.
- neu: Regeln aus deiner Compositor-Konfiguration; hier sind sie schreibgeschützt. Mit «In Alpe konvertieren» legst du eine bearbeitbare Kopie an.

**71** `Run an external command on each wallpaper change and merge its JSON palette into %1 under a namespace, so templates can use e.g. %2. The command receives the wallpaper as %3 and the mode as %4.`
- heute: Führen Sie bei jedem Hintergrundbildwechsel einen externen Befehl aus und führen Sie dessen JSON-Palette unter einem Namespace in %1 zusammen, sodass Vorlagen bspw. %2 verwenden können. Der Befehl empfängt das Hintergrundbild als %3 und den Modus als %4.
- neu: Führt bei jedem Wechsel des Hintergrundbilds einen externen Befehl aus und fügt dessen JSON-Palette unter einem Namespace in %1 ein, sodass Vorlagen z. B. %2 verwenden können. Der Befehl erhält das Hintergrundbild als %3 und den Modus als %4.

**72** `Save your work first. Open apps will close.`
- heute: Speichern Sie zuerst Ihre Arbeit. Geöffnete Apps werden geschlossen.
- neu: Speichere zuerst deine Arbeit. Geöffnete Apps werden geschlossen.

**73** `Security-key support was detected, but no registered key was found yet. You can enable this now and register one later.`
- heute: Unterstützung für Sicherheitsschlüssel wurde erkannt, aber es wurde noch kein registrierter Schlüssel gefunden. Sie können dies jetzt aktivieren und später einen registrieren.
- neu: Unterstützung für Sicherheitsschlüssel erkannt, aber noch kein registrierter Schlüssel gefunden. Du kannst das jetzt aktivieren und später einen registrieren.

**74** `Select a widget to add. You can add multiple instances of the same widget if needed.`
- heute: Wählen Sie ein Widget aus, das Sie hinzufügen möchten. Bei Bedarf können Sie mehrere Instanzen desselben Widgets hinzufügen.
- neu: Wähle ein Widget zum Hinzufügen. Bei Bedarf kannst du dasselbe Widget mehrfach hinzufügen.

**75** `Select an active session to switch to. The current session stays running in the background.`
- heute: Wählen Sie eine aktive Sitzung aus, zu der Sie wechseln möchten. Die aktuelle Sitzung bleibt im HIntergrund am Laufen.
- neu: Wähle eine aktive Sitzung, zu der du wechseln möchtest. Die aktuelle Sitzung läuft im Hintergrund weiter.
- nebenbei: Tippfehler «HIntergrund».

**76** `Set custom names for your audio input devices`
- heute: Benutzerdefinierte Namen für Ihre Audioeingabegeräte festlegen
- neu: Eigene Namen für deine Audioeingabegeräte festlegen

**77** `Set custom names for your audio output devices`
- heute: Benutzerdefinierte Namen für Ihre Audioausgabegeräte festlegen
- neu: Eigene Namen für deine Audioausgabegeräte festlegen

**78** `Set one of these environment variables, then restart the shell:\n%1\n\nOnly %2 requires %3 to be installed.`
- heute: Legen Sie eine dieser Umgebungsvariablen fest, dann starten Sie die Shell neu:\n%1\n\nNur %2 erfordert die Installation von %3.
- neu: Leg eine dieser Umgebungsvariablen fest und starte die Shell neu:\n%1\n\nNur %2 erfordert die Installation von %3.

**79** `Set up a Wi-Fi hotspot for sharing this connection.`
- heute: Richten Sie einen WLAN-Hotspot ein, um diese Verbindung freizugeben.
- neu: Richte einen WLAN-Hotspot ein, um diese Verbindung freizugeben.

**80** `Start typing your notes here...`
- heute: Starten Sie hier, Ihre Notiz einzutippen ...
- neu: Schreib hier deine Notizen …

**81** `System sounds are not available. Install %1 for sound support.`
- heute: Systemklänge sind nicht verfügbar. Installieren Sie %1 für Sound-Unterstützung.
- neu: Systemklänge sind nicht verfügbar. Installiere %1 für Klänge.

**82** `Terminal fallback failed. Install one of the supported terminal emulators or run '%1' manually.`
- heute: Terminal-Fallback fehlgeschlagen. Installieren Sie einen der unterstützten Terminal-Emulatoren oder führen Sie '%1' manuell aus.
- neu: Ausweichen auf das Terminal fehlgeschlagen. Installiere einen der unterstützten Terminal-Emulatoren oder führ «%1» von Hand aus.

**83** `Terminal fallback opened. Complete authentication there; it will close automatically when done.`
- heute: Terminal-Fallback geöffnet. Schliessen Sie dort die Authentifizierung ab; es wird nach Abschluss automatisch geschlossen.
- neu: Terminal als Ausweichweg geöffnet. Schliess die Authentifizierung dort ab; es schliesst sich danach von selbst.

**84** `Terminal opened. Complete authentication there; it will close automatically when done.`
- heute: Terminal geöffnet. Schliessen Sie dort die Authentifizierung ab; es wird nach Abschluss automatisch geschlossen.
- neu: Terminal geöffnet. Schliess die Authentifizierung dort ab; es schliesst sich danach von selbst.

**85** `The below settings will modify your GTK and Qt settings. If you wish to preserve your current configurations, please back them up (%1 and %2).`
- heute: Die folgenden Einstellungen werden Ihre GTK- und Qt-Einstellungen ändern. Wenn Sie Ihre aktuellen Konfigurationen beibehalten möchten, sichern Sie diese bitte (%1 und %2).
- neu: Die folgenden Einstellungen ändern deine GTK- und Qt-Einstellungen. Wenn du deine aktuellen Konfigurationen behalten möchtest, sichere sie vorher (%1 und %2).

**86** `The server certificate has changed since it was last trusted. Only continue if you recognize the new fingerprint.`
- heute: Das Serverzertifikat hat sich seit der letzten Vertrauensbestätigung geändert. Fahren Sie nur fort, wenn Sie den neuen Fingerabdruck erkennen.
- neu: Das Serverzertifikat hat sich geändert, seit ihm zuletzt vertraut wurde. Fahr nur fort, wenn du den neuen Fingerabdruck kennst.

**87** `This plugin does not have '%1' permission.\n\nAdd %2 to %3`
- heute: Dieses Plugin hat keine '%1'-Berechtigung.\n\nFügen Sie %2 zu %3 hinzu
- neu: Dieses Plugin hat die Berechtigung «%1» nicht.\n\nFüge %2 zu %3 hinzu

**88** `To sign in as a different user, log out and pick the account from the greeter. Creating a fresh session in parallel needs a multi-session greeter (%1).`
- heute: Um sich als anderer Benutzer anzumelden, melden Sie sich ab und wählen Sie das Konto aus dem Greeter. Um parallel eine neue Sitzung zu erstellen, benötigt es einen Mulit-Session-Greeter (%1).
- neu: Um dich als anderer Benutzer anzumelden, melde dich ab und wähle das Konto im Greeter. Eine neue Sitzung parallel dazu braucht einen Multi-Session-Greeter (%1).
- nebenbei: Tippfehler «Mulit».

**89** `To use this Alpe bind, remove or change the keybind in your %1`
- heute: Um diese Alpe-Bindung zu verwenden, entfernen oder ändern Sie die Tastenbelegung in Ihrem %1
- neu: Um diese Alpe-Bindung zu verwenden, entferne oder ändere die Tastenbelegung in deinem %1

**90** `Touch your security key...`
- heute: Berühren Sie Ihren Sicherheitsschlüssel ...
- neu: Berühre deinen Sicherheitsschlüssel …

**91** `Try a different search`
- heute: Probieren Sie eine andere Suche
- neu: Versuch eine andere Suche

**92** `Type at least 2 characters`
- heute: Tippen Sie mindestens 2 Zeichen ein
- neu: Gib mindestens 2 Zeichen ein

**93** `Use keys 1-3 or arrows, Enter/Space to select`
- heute: Verwenden Sie die Tasten 1-3 oder die Pfeiltasten, Enter/Leertaste zum Auswählen
- neu: Tasten 1–3 oder Pfeiltasten, Enter/Leertaste zum Auswählen

**94** `Uses sunrise/sunset times based on your location.`
- heute: Verwendet Sonnenaufgangs-/-untergangszeiten basierend auf Ihrem Standort.
- neu: Verwendet die Zeiten von Sonnenauf- und -untergang an deinem Standort.

**95** `Wi-Fi is disabled. You can still edit and save hotspot settings, but starting the hotspot requires Wi-Fi to be enabled.`
- heute: WLAN ist deaktiviert. Sie können Hotspot-Einstellungen weiterhin bearbeiten und speichern, aber zum Starten des Hotspots muss WLAN aktiviert sein.
- neu: WLAN ist deaktiviert. Du kannst die Hotspot-Einstellungen weiterhin bearbeiten und speichern, aber zum Starten des Hotspots muss WLAN aktiviert sein.

**96** `Wrap the app command. %command% is replaced with the actual executable`
- heute: Umschliessen Sie den App-Befehl. %command% wird durch die tatsächliche ausführbare Datei ersetzt
- neu: Umschliesst den App-Befehl. %command% wird durch das eigentliche Programm ersetzt

**97** `You have unsaved changes. Save before continuing?`
- heute: Sie haben ungespeicherte Änderungen. Speichern, bevor Sie fortfahren?
- neu: Du hast ungespeicherte Änderungen. Vor dem Fortfahren speichern?

**98** `You're all caught up`
- heute: Jetzt sind Sie auf dem neuesten Stand
- neu: Du bist auf dem neuesten Stand

**99** `Your compositor does not support ext-background blur`
- heute: Ihr Compositor unterstützt keine ext-background-Unschärfe
- neu: Dein Compositor unterstützt keine ext-background-Unschärfe

**100** `Your hotspot is running.`
- heute: Ihr Hotspot wird ausgeführt.
- neu: Dein Hotspot läuft.

**101** `Your hotspot profile is saved and ready to start.`
- heute: Ihr Hotspot-Profil ist gespeichert und startbereit.
- neu: Dein Hotspot-Profil ist gespeichert und startbereit.

**102** `Your keyboard layout puts %1 above the first level, so this bind will never fire. Pick a key the layout types without an extra layer.`
- heute: Ihr Tastaturlayout legt %1 über die erste Ebene, daher wird diese Bindung niemals ausgelöst. Wählen Sie eine Taste, die das Layout ohne zusätzliche Ebene tippt.
- neu: Dein Tastaturlayout legt %1 über die erste Ebene, daher löst diese Bindung nie aus. Wähle eine Taste, die das Layout ohne zusätzliche Ebene erzeugt.

**103** `Your system is up to date!`
- heute: Ihr System ist auf dem neuesten Stand!
- neu: Dein System ist auf dem neuesten Stand!

## Fragen an den Maintainer

1. **«Ctrl» oder «Strg»** (Nr. 38, 62): Die Schweizer Tastatur ist mit «Ctrl» beschriftet, der Katalog
   des Ursprungs schreibt «Strg». Der Vorschlag setzt in den zwei Einträgen «Ctrl». Soll das für den
   ganzen Katalog gelten (eigener Durchgang über alle Vorkommen), oder bleiben die zwei bei «Strg»?
2. **Kurzer Imperativ** («Klick», «Zieh», «Steck», «Schliess») statt der Form mit -e («Klicke»,
   «Ziehe»): So vorgeschlagen, weil es gesprochen klingt; bei Verben auf -ern/-igen/-ieren bleibt das
   -e («Überprüfe», «Speichere», «Installiere»). Recht so, oder durchgehend mit -e?
3. **Höflichkeitsfloskel «Bitte»** (Nr. 33, 46, 60, 64, 85) ist im Vorschlag weggelassen. Recht so?
4. **Was die Suche nicht findet:** Sie-Form ohne die genannten Wörter gibt es nicht (ein Imperativ in
   Sie-Form enthält immer «Sie»). Unpersönliche Formen des Katalogs («Bitte warten», Infinitive als
   Aufforderung) sind keine Sie-Form und stehen nicht auf der Liste.

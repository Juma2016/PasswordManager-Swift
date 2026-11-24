# PasswordManager

Einfacher iOS-Passwort-Manager mit **SwiftUI**, **Swift 6**, **Keychain** und **Face ID** (Abgabe A1 – Native Mobile Development, FH JOANNEUM).

## Funktionen

- Einträge (Titel, Benutzername, Passwort) sicher in der iOS-Keychain (`kSecClassGenericPassword`) speichern
- Schutz jedes Passworts über `SecAccessControl` (`.biometryCurrentSet`)
- Face-ID-Abfrage direkt über die Keychain (`LAContext` + `kSecUseAuthenticationContext`)
- Fehlerbehandlung für Abbruch, fehlgeschlagene Authentifizierung und neu eingerichtete Face ID
- Unit-Tests mit Swift Testing (`PasswordManagerTests`)

## Ausführen im Simulator

1. Projekt `PasswordManager.xcodeproj` in Xcode öffnen (iOS 18.0+, Swift 6).
2. App im Simulator starten (`Cmd + R`).
3. Im Simulator **Features → Face ID → Enrolled** aktivieren.
4. Zum Testen beim Öffnen eines Eintrags **Matching Face**, **Non-matching Face** oder **Abbrechen** testen.

## Begründung: `.biometryCurrentSet` vs. `.userPresence`

Für einen Passwort-Manager ist `.biometryCurrentSet` aus Sicherheitsgründen die bessere Wahl, 
weil gespeicherte Passwörter automatisch unlesbar werden, 
sobald auf dem Gerät ein neues Gesicht oder ein neuer Finger hinzugefügt wird. 
Bei `.userPresence` reicht hingegen auch der Gerätecode aus, und die Einträge bleiben selbst nach einer Änderung der Biometrie weiterhin lesbar. 
Wenn jemand den Gerätecode kennt, könnte er bei `.userPresence` auf alle Passwörter zugreifen oder eigene Biometrie hinzufügen. 
Der Nachteil von `.biometryCurrentSet` ist zwar, dass Einträge nach einem Face-ID-Reset neu angelegt werden müssen, 
aber bei sensiblen Passwörtern ist der höhere Schutz vor unbefugtem Zugriff wichtiger als der Komfort.

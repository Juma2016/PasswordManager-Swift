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

Ich finde `.biometryCurrentSet` für einen Passwort-Manager besser, weil die Passwörter geschützt bleiben sollen. 
Wenn Face ID neu eingerichtet wird, können die alten Einträge nicht mehr gelesen werden. 
Bei `.userPresence` kann man auch den Gerätecode verwenden. 
Außerdem bleiben die Einträge nach einer Änderung von Face ID lesbar. 
Deshalb würde ich `.biometryCurrentSet` verwenden, auch wenn man die Einträge nach einem Face-ID-Reset neu anlegen muss.

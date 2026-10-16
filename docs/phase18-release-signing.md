# Production upload signing

Status: **BLOCKED — PRODUCTION UPLOAD KEY REQUIRED** (2026-10-16).

No android/key.properties exists in this workspace. No upload key was generated, modified or requested externally. Earlier local release artifacts use Android Debug credentials and are not for distribution.

Release now selects a dedicated `upload` signing configuration. Both preReleaseBuild and validateSigningRelease depend on validateUploadSigning. The guard rejects missing/blank properties, missing files, inaccessible keys/passwords/aliases, expired certificates and Android Debug keys. It validates every run, including cached builds. AGP still performs its own signing validation. Debug does not require upload properties. There is no debug fallback.

## Owner actions, in order

1. Check whether a securely stored upload key already exists for this product. Recover it instead of replacing it. Confirm the expected certificate fingerprint with the owner/Play Console.
2. If none exists, choose a new path outside this repository, ensure it does not already exist, and generate the upload key interactively using Android Studio or Java keytool. The following is an example for the owner to execute, not a command executed during this task:

   ```powershell
   keytool -genkeypair -v -keystore C:/secure/engineering-toolkit-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Supply owner-selected passwords at the prompts. Never put them on a command line or in this document. Do not overwrite a keystore. Restrict filesystem access to the owner.
3. Store passwords in the owner's password manager. Keep encrypted backups of the keystore and recovery instructions in at least two owner-controlled locations, separate from the passwords. Verify recovery before relying on this key.
4. Create local `android/key.properties`, already ignored by Git, with four fields: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Use the real private values locally. Use an absolute path with forward slashes on Windows; relative paths resolve against the android directory. Do not paste credentials into chat, commit them, or include them in logs/screenshots. This standard Java properties file is plaintext: restrict its permissions and keep it outside shared/synced copies. No example credential file is committed.
5. Run `flutter build appbundle --release`. Verify the signing certificate fingerprint against the approved upload certificate, package ID/version, permissions/backup/resources, 64-bit and 16 KB compatibility, and SHA-256. Validity checks cannot establish ownership of an arbitrary non-debug key; the owner must confirm that fingerprint.
6. Review Play App Signing setup in Play Console. An upload key authenticates uploads; Play's app-signing key signs delivered APKs. Console configuration and upload are owner actions, outside this task.

The application does not become publication-ready merely because this guard passes. Never substitute a temporary/test key to claim production readiness. Do not bypass the guard or distribute any stale debug-signed APK/AAB left in build outputs.

References: [Flutter signing guide](https://docs.flutter.dev/deployment/android#sign-the-app), [Android app signing](https://developer.android.com/studio/publish/app-signing).

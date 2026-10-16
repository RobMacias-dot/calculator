# Permanent Android identity

Android applicationId, namespace and Kotlin activity package are now `com.robmac.engineeringtoolkit`. Dart package stays `engineering_toolkit`; display label stays Engineering Toolkit. Manifest `.MainActivity` resolves against the new namespace; AndroidX provider authorities and internal signature permission are generated from the application ID. Flutter embedding v2 and automatic plugin registration are unchanged. Backup XML is unchanged.

The former `com.engineeringtoolkit.engineering_toolkit` installation and the new identity can coexist. Android treats them as separate apps with separate private storage. No automatic migration is implemented. Do not uninstall or clear the old installation. The new identity was not installed on the owner's physical device during this run; device validation requires the owner.

# Keihatsu Release Workflow Guide

This guide covers everything you need to know about the automated release workflow configured for your Flutter application.

## 1. Setting Up GitHub Secrets

To make the workflow run securely and handle integrations like Firebase and (later) Android App Signing, you need to add Secrets to your GitHub repository.

### Steps to add a secret:
1. Go to your repository on GitHub.
2. Click on **Settings** > **Secrets and variables** > **Actions**.
3. Click the **New repository secret** button.
4. Add the following secrets:

#### Required Now (for Firebase):
- **`GOOGLE_SERVICES_JSON`**
  - **Value:** The complete text contents of `apps/flutter/android/app/google-services.json`. Just open the file in your code editor, copy everything, and paste it here.

#### For Future Use (When you want to build signed APKs):
- **`KEY_ALIAS`**
  - **Value:** The alias of your keystore (e.g., `upload` as seen in your `key.properties`).
- **`KEY_PASSWORD`**
  - **Value:** The password for the key.
- **`STORE_PASSWORD`**
  - **Value:** The password for the keystore.
- **`KEYSTORE_BASE64`**
  - **Value:** Your keystore needs to be base64-encoded to store as a secret. Run this PowerShell command in your terminal to generate the string and copy it to your clipboard:
    ```powershell
    [convert]::ToBase64String((Get-Content -path "apps\flutter\android\upload-keystore.jks" -Encoding byte)) | clp
    ```

---

## 2. How to Trigger the Workflow

The workflow is configured to run ONLY when a new tag that starts with `v` is pushed to the repository. 

Here is the exact step-by-step process you should use in your Git terminal when you're ready to release a new version:

1. **Update the version in `apps/flutter/pubspec.yaml`** (e.g., change `version: 1.2.0+4` to `version: 1.3.0+5`).
2. **Commit your changes:**
   ```bash
   git add apps/flutter/pubspec.yaml
   git commit -m "chore: bump version to 1.3.0"
   git push
   ```
3. **Create a git tag** that MUST match the version in `apps/flutter/pubspec.yaml`:
   ```bash
   git tag v1.3.0
   ```
4. **Push the tag to GitHub:**
   ```bash
   git push origin v1.3.0
   ```

*Once the tag is pushed, the `🚀 Release APK` workflow will start automatically, build the APK, and create a GitHub Release.*

---

## 3. How to Enable Android App Signing Securely

Right now, the workflow successfully builds an **unsigned** release APK. This is because we commented out the signing step in `.github/workflows/release.yml` so you don't face errors before setting up your secrets.

When you are ready to sign your release APKs, simply follow these steps:

1. Ensure the 4 Signing Secrets mentioned in section 1 (`KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`) are added to your GitHub repository.
2. Open `.github/workflows/release.yml`.
3. Locate **Step 7: Set up Android Signing (OPTIONAL / FUTURE)** (around line 133).
4. Uncomment the entire block by removing the `#` before the steps, so it looks exactly like this:

```yaml
      # -----------------------------------------------------------------------
      # 7. Set up Android Signing (OPTIONAL / FUTURE)
      # -----------------------------------------------------------------------
      - name: 🔐 Set up Android signing
        if: secrets.KEYSTORE_BASE64 != '' && secrets.KEY_ALIAS != ''
        run: |
          # Decode keystore
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

          # Create key.properties
          cat > android/key.properties << EOF
          storePassword=${{ secrets.STORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=upload-keystore.jks
          EOF

          echo "✅ Signing configured"
```

Once uncommented, the next push of a `v*` tag will inject the `key.properties` and the keystore `.jks` file securely, and Flutter will use them natively via your existing `build.gradle.kts` setup to output a signed APK!

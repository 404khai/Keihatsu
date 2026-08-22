# Keihatsu iOS Distribution Guide (No App Store)

If you do not want to publish to the App Store (either to avoid the review process, fees, or content restrictions), you have several options to distribute your app directly to users.

Since you are on Windows, you will still need to use a **Cloud Build Service** (like Codemagic) to generate the `.ipa` file first (see `IOS_BUILD_GUIDE.md`).

## 1. The "Side-Loading" Method (Free, Most Popular)
This is the standard way for manga/anime apps (like Tachiyomi forks, Paperback, etc.) to distribute on iOS without the App Store.

### How it works
1.  **You** build the `.ipa` file (using Codemagic/GitHub Actions).
2.  **You** host the `.ipa` file on GitHub Releases or your website.
3.  **Users** install the app using a tool like **AltStore** or **SideStore**.

### Pros & Cons
*   **Pros**: Free for you. No Apple Review. Updates are handled by the user.
*   **Cons**: Users must refresh the app every 7 days (unless they have a paid developer account). Requires users to have a PC/Mac to set up initially.

### Instructions for Users
1.  Download the **Keihatsu.ipa** from your releases.
2.  Install [AltStore](https://altstore.io/) on their phone.
3.  Open AltStore -> My Apps -> + -> Select `Keihatsu.ipa`.

## 2. TestFlight (Official Beta Testing)
If you are willing to pay the **$99/year Apple Developer Fee**, this is the best experience.

### How it works
1.  **You** sign up for the Apple Developer Program ($99/year).
2.  **You** upload the build to App Store Connect (via Codemagic).
3.  **You** create a "Public Link" in TestFlight.
4.  **Users** download the "TestFlight" app from the App Store and tap your link.

### Pros & Cons
*   **Pros**: Easy one-tap install for users. Auto-updates. No 7-day refresh. 10,000 user limit.
*   **Cons**: Costs $99/year. Requires a light "Beta App Review" (Apple might still reject manga apps if they contain pirated content). Builds expire after 90 days (you must upload a new one).

## 3. Ad Hoc Distribution (For Small Groups)
Also requires the **$99/year Apple Developer Fee**.

### How it works
1.  **You** ask users for their device **UDID** (Unique Device Identifier).
2.  **You** register these UDIDs in your Apple Developer Account.
3.  **You** build a special `.ipa` that includes these UDIDs.
4.  **You** upload the `.ipa` to a service like [Diawi](https://www.diawi.com/) or [InstallOnAir](https://www.installonair.com/).
5.  **Users** tap the link and install directly.

### Pros & Cons
*   **Pros**: Direct install link. No 7-day refresh.
*   **Cons**: Costs $99/year. Limited to 100 devices. You must rebuild the app every time you add a new user. Tedious management.

---

## Recommendation for Keihatsu

**Option 1 (Side-Loading)** is the standard for manga apps.
1.  Use **Codemagic** to build an **Unsigned** or **Ad-Hoc Signed** `.ipa`.
2.  Upload the `.ipa` to GitHub Releases.
3.  Tell users to use **AltStore** to install it.

### Setting up Codemagic for "Unsigned" Build
In your `codemagic.yaml` or UI settings:
1.  Set "Build mode" to `Release`.
2.  Under "Distribution", choose "iOS code signing" -> "Automatic code signing".
3.  If you don't have a developer account, you might need to select "No signing" (Build for iOS Simulator or generic device), but usually, you need *some* signature.
    *   *Workaround*: Create a free Apple ID. Use Xcode (on a Mac/Cloud Mac) to generate a "Personal Team" certificate. Export it. Use that in Codemagic.

**Note**: Without a Mac to generate the initial signing certificate, it is very hard to generate a valid `.ipa` even for AltStore. **AltStore requires the IPA to be validly structured.**

**Crucial Step for Windows Users:**
You *must* get a valid signing identity (Certificate .p12 + Provisioning Profile .mobileprovision) to build an IPA that installs on real devices, even for AltStore.
*   **Cheapest Way**: Ask a friend with a Mac to generate a "Development Certificate" for your Apple ID and export it for you.
*   **Paid Way**: Buy a generic signing certificate from a service like appdb/Signulous, or pay the $99 Apple fee.

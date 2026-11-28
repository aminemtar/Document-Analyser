# Data safety / privacy labels

Answers matching what the app does today. Re-check whenever you add analytics,
crash reporting, accounts or a backend.

## Google Play, Data safety form

| Question | Answer |
|---|---|
| Does the app collect or share user data? | Yes |
| Is data encrypted in transit? | Yes (HTTPS) |
| Can users request data deletion? | No account exists; data is local. Say so in the policy |

Data types:

| Type | Collected | Shared | Purpose | Optional |
|---|---|---|---|---|
| Files and docs (document text sent to the AI service) | Yes | Yes (AI provider acting as service provider) | App functionality | No (needed for analysis) |
| Device or other IDs (advertising ID) | Yes | Yes (Google AdMob) | Advertising | Yes, ad-free for 24 h after a rewarded ad |
| App interactions / diagnostics from ads SDK | Yes | Yes (AdMob) | Advertising, analytics | Yes, ad-free for 24 h after a rewarded ad |
| Approximate location (derived from IP by AdMob) | Yes | Yes (AdMob) | Advertising | Yes, ad-free for 24 h after a rewarded ad |

Not collected: name, email, phone, photos/videos stored by us, contacts, precise location, health, financial info.
This edition has no in-app purchases (answer "No" to purchases). Also declare: Advertising ID usage (the app has the AD_ID permission), and in "App content" tick "Contains ads".

## Apple, App Privacy ("nutrition labels")

| Data | Linked to user | Used for tracking | Purpose |
|---|---|---|---|
| Other user content (document text sent for analysis) | No | No | App functionality |
| Identifiers: Device ID (advertising) | No | Yes, only if ATT is granted | Third-party advertising |
| Usage data: product interaction, advertising data | No | Yes, only if ATT is granted | Third-party advertising |

iOS reminders before submission:
- Add `NSUserTrackingUsageDescription` to Info.plist and show the ATT prompt, or ship iOS with non-personalized ads only and answer "no tracking".
- Add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` strings (scan).
- Add a Privacy Manifest if your SDK versions require it.
- Provide the privacy policy URL.

## Age and content rating
- Google Play (IARC questionnaire): utility app, no violence/sexual content/gambling, contains ads. Expected rating: Everyone.
- Apple: 4+ (no objectionable content). The AI can summarize any user document, so answer "no" to unrestricted web access but mention user-generated content only if asked.

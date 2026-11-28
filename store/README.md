# Store pack

| Folder / file | What it is |
|---|---|
| `play/icon-512.png` | Google Play app icon (512x512) |
| `play/feature-graphic-{en,fr,ar}-1024x500.png` | Play feature graphic / banner per language |
| `appstore/icon-1024.png` | App Store icon (1024x1024, no transparency) |
| `listings.md` | Titles, descriptions, keywords, subscriptions in EN / FR / AR |
| `privacy-policy.md` | Policy template EN + FR to host publicly |
| `data-safety.md` | Answers for Play Data safety and Apple privacy labels |
| `screenshots-tool/` | Adds a headline and phone frame to your raw screenshots |
| `build_graphics.py` | Regenerates the icons and banners |

## Taking the screenshots (8 shots)
Use a release or profile build, a clean demo account of documents, dark and light as noted. Phone 1080x1920 or taller (Pixel emulator works). Language: take each set in EN, FR and AR (RTL).

1. Home with 2 or 3 documents (light)
2. Analysis result, Summary tab
3. Analysis, Dates tab with deadlines (dark)
4. Assistant answering a question
5. Scan screen with a photographed page
6. Compare two documents
7. Profile / backup / privacy
8. Language sheet or dark mode toggle

The order matches `screenshots-tool/captions.json`.

Frame them (name the files 01.png ... 08.png in one folder per language):
```bash
pip install pillow
python3 store/screenshots-tool/frame.py --lang en --size play --in shots/en --out store/out/play-en
python3 store/screenshots-tool/frame.py --lang fr --size ios  --in shots/fr --out store/out/ios-fr
```
`play` gives 1080x1920, `ios` gives 1290x2796 (App Store 6.7"). Play needs 2 to 8 phone screenshots, so also capture on an iPhone simulator for the App Store.

Regenerate graphics after changing the logo:
```bash
python3 store/build_graphics.py
```

## Checklist before publishing
- [ ] Real AdMob app and ad unit IDs in `lib/config/ad_config.dart`, AndroidManifest and Info.plist; build with `--dart-define=ADS_LIVE=true`
- [ ] Ads-only edition: no subscriptions to create (see ADS-ONLY.md)
- [ ] Release signing key created and backed up (never commit it); Play App Signing on
- [ ] Application id changed from `com.example.documind_ai` to your own
- [ ] Privacy policy hosted, URL added in both stores and inside the app (Profile)
- [ ] Data safety form and Apple privacy labels filled from `data-safety.md`
- [ ] Content rating questionnaire done
- [ ] Spend limit set on the OpenRouter key (the key is bundled in the app and can be extracted)
- [ ] Apple review notes: "No login required. Subscriptions can be tested via sandbox. Document analysis needs internet."
- [ ] Test on a real device: purchase, restore, notifications, share-into-app, RTL
- [ ] Build: `flutter build appbundle --release --obfuscate --split-debug-info=symbols/`

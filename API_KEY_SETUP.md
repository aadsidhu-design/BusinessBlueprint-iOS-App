# API Key Setup Guide

## 🔑 Required API Keys

This app requires a Google AI Studio API key to function. Follow these steps to set it up:

### 1. Get Your Google AI Studio API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

### 2. Configure in Xcode

You have two options to provide your API key:

#### Option A: Xcode Build Settings (Recommended)

1. Open the project in Xcode
2. Select the **businessapp** target
3. Go to **Build Settings** tab
4. Search for "User-Defined"
5. Click the **+** button to add a new User-Defined Setting
6. Name it: `GOOGLE_AI_API_KEY`
7. Set the value to your actual API key
8. Repeat for `FIREBASE_WEB_API_KEY` (optional, for future features)

#### Option B: Environment Variables

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** on the left
3. Go to the **Arguments** tab
4. Under "Environment Variables", add:
   - Name: `GOOGLE_AI_API_KEY`
   - Value: Your actual API key

### 3. Verify Setup

The Info.plist file uses placeholders that will be replaced at build time:

```xml
<key>GOOGLE_AI_API_KEY</key>
<string>$(GOOGLE_AI_API_KEY)</string>
```

When you build, Xcode will automatically substitute `$(GOOGLE_AI_API_KEY)` with your actual key.

### 4. Security Notes

✅ **DO:**
- Use User-Defined Build Settings or Environment Variables
- Keep your `.env.local` file out of version control
- Use the `.env.example` template for reference
- Use build configuration-specific keys (Debug vs Release)

❌ **DON'T:**
- Never hardcode API keys in source files
- Never commit `.env.local` or actual keys to git
- Never share your API keys publicly

## 🔥 Firebase Setup (Optional)

Firebase features are currently mocked. To enable real Firebase:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app to your project
3. Download `GoogleService-Info.plist`
4. Add your Web API Key to build settings as `FIREBASE_WEB_API_KEY`

## 🧪 Testing Without API Keys

The app includes fallback business ideas that work without API keys for testing. However, for full AI features:

- Quiz question generation
- Business idea generation
- AI suggestions and advice

You'll need a valid Google AI Studio API key.

## 📱 Building for Different Configurations

### Debug (Development)
- Uses API keys from Xcode settings or environment
- Includes verbose logging

### Release (Production)
- Same API key source
- Optimized build
- Reduced logging

## 🆘 Troubleshooting

### Error: "GOOGLE_AI_API_KEY not set"

This means the app can't find your API key. Check:

1. ✓ Did you add it to Xcode Build Settings?
2. ✓ Did you spell `GOOGLE_AI_API_KEY` correctly?
3. ✓ Did you rebuild the project after adding it?

### API Key Not Working

1. Verify your key at [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Check if the key has been deactivated
3. Generate a new key if needed
4. Update your build settings

## 📞 Support

For issues with:
- **Google AI Studio API**: [Google AI Support](https://ai.google.dev/support)
- **Firebase**: [Firebase Support](https://firebase.google.com/support)
- **This App**: Check the README.md or create an issue

# QuickLook Extension Testing Guide

## Simulator Limitations 🚨

iOS Simulators have several sharing restrictions:
- **No AirDrop** (requires real hardware)
- **Limited Share Sheet** options
- **Messages app** may not show all file sharing options
- **Files app** sharing is restricted

## Testing Methods

### 1. Files App Direct Preview (Simulator ✅)
- Open Files app
- Navigate to your `.magicard` file
- **Tap the file directly** - this should trigger QuickLook
- Look for your Planet Nine preview instead of raw JSON

### 2. Mail App Test (Simulator ✅)
- Open Mail app
- Compose new message
- Try to attach the `.magicard` file
- Should show QuickLook preview in attachment

### 3. Real Device Testing (Required for Full Test)
- **Messages**: Full sharing functionality
- **AirDrop**: Works between devices
- **Share Sheet**: Complete options

### 4. Alternative Simulator Testing

Try these workarounds:

#### A. Safari Download Test
Create a simple HTML file that links to the .magicard:
```html
<a href="debug-quicklook.magicard" download>Download MagiCard</a>
```

#### B. Email Yourself Test
- Email the file from Mac to simulator
- Open in Mail app
- Tap attachment to see preview

## Expected QuickLook Behavior

When working correctly, you should see:
- ✅ Planet Nine gradient background
- ✅ SVG card rendered in preview
- ✅ "QuickLook Test Card" title
- ✅ Verification badge
- ✅ "Open in The Advancement" button
- ❌ NOT raw JSON text

## Debugging Steps

1. **Check Extension Loading**:
   - Device logs should show AdvanceLook extension loading
   - Check Xcode console for any errors

2. **File Type Recognition**:
   - Files app should show custom icon (if configured)
   - File should not show as "unknown type"

3. **Preview Generation**:
   - QuickLook should call our `preparePreviewOfFile` method
   - HTML should be generated and displayed

## Real Device Test Priority

The most reliable test is on a **real iPhone/iPad**:
- Full sharing functionality
- Proper Messages app integration
- AirDrop testing between devices
- Complete QuickLook framework behavior
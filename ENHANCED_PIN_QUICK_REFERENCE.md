# EnhancedPinScreen - Quick Reference

## 🚀 **Import**
```dart
import '../../../app/utils/widgets/enhanced_pin_screen.dart';
```

## ⚡ **Quick Usage**

### **Set PIN (4-digit)**
```dart
EnhancedPinScreen(
  title: "Set PIN",
  subtitle: "Enter new PIN",
  type: PinScreenType.set,
  fieldType: InputFieldType.pin,
  onPinConfirmed: (pin) => savePIN(pin),
)
```

### **Verify PIN**
```dart
EnhancedPinScreen(
  title: "Enter PIN", 
  subtitle: "Verify your PIN",
  type: PinScreenType.verify,
  fieldType: InputFieldType.pin,
  existingPin: "1234",
  onPinComplete: (pin) => proceed(),
)
```

### **Set Password**
```dart
EnhancedPinScreen(
  title: "Create Password",
  subtitle: "Enter password", 
  type: PinScreenType.set,
  fieldType: InputFieldType.password,
  onPinConfirmed: (pwd) => savePassword(pwd),
)
```

### **Login Password**
```dart
EnhancedPinScreen(
  title: "Login",
  subtitle: "Enter password",
  type: PinScreenType.verify,
  fieldType: InputFieldType.password,
  existingPin: userPassword,
  onPinComplete: (pwd) => login(),
)
```

### **6-Digit PIN**
```dart
EnhancedPinScreen(
  title: "Security PIN",
  subtitle: "Enter 6-digit PIN",
  type: PinScreenType.set,
  fieldType: InputFieldType.pin,
  inputLength: 6,
  onPinConfirmed: (pin) => save6DigitPIN(pin),
)
```

## 🎛️ **Key Parameters**

| Parameter | Values | Description |
|-----------|--------|-------------|
| `type` | `set`, `verify`, `change`, `confirm` | Screen behavior |
| `fieldType` | `pin`, `password` | Input field type |
| `inputLength` | `4`, `6`, etc. | PIN length |
| `showKeypad` | `true`, `false` | Show custom keypad |
| `existingPin` | `"1234"` | PIN to verify against |

## 🎨 **Customization**

```dart
EnhancedPinScreen(
  // ... basic params
  backgroundColor: Colors.blue[50],
  showBackButton: false,
  hintText: "Custom hint",
  errorMessage: "Custom error",
  obscureText: false,
)
```

## 📱 **Common Patterns**

### **Transaction Confirmation**
```dart
EnhancedPinScreen(
  title: "Confirm Transaction",
  subtitle: "Enter PIN to send ₦$amount",
  type: PinScreenType.verify,
  fieldType: InputFieldType.pin,
  existingPin: getUserPin(),
  onPinComplete: (pin) => processTransaction(),
)
```

### **App Lock Screen**
```dart
EnhancedPinScreen(
  title: "App Locked",
  subtitle: "Enter PIN to unlock",
  type: PinScreenType.verify,
  fieldType: InputFieldType.pin,
  showBackButton: false,
  existingPin: getAppPin(),
  onPinComplete: (pin) => unlockApp(),
)
```

### **Settings PIN Change**
```dart
EnhancedPinScreen(
  title: "Change PIN",
  subtitle: "Enter new PIN",
  type: PinScreenType.change,
  fieldType: InputFieldType.pin,
  onPinConfirmed: (pin) => updatePIN(pin),
)
```

## ✅ **Benefits**
- **90% less code** than custom implementations
- **Consistent UI** across all PIN/password screens
- **Flexible** - handles PIN fields, password fields, any length
- **Reusable** - one component for all scenarios
- **Maintainable** - update once, applies everywhere
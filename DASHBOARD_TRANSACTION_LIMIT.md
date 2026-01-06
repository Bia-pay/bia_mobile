# Dashboard Transaction Display - 2 Most Recent Only

## ✅ Fixed: Homepage Transaction Limit

**Change Made:**
```dart
// Before: Show all cached transactions
itemCount: transactions.length,

// After: Show only 2 most recent
itemCount: transactions.length > 2 ? 2 : transactions.length,
```

## 🎯 Behavior Now

### Homepage Dashboard:
- ✅ **Shows exactly 2 transactions** - the most recent ones
- ✅ **Cached data first** - Instant display from cache
- ✅ **API updates** - Smoothly updates when fresh data arrives
- ✅ **No matter cache size** - Always limits to 2 most recent

### Example Scenarios:

**Scenario 1: 5 cached transactions**
- Dashboard shows: 2 most recent
- Transaction history shows: All 5

**Scenario 2: 2 new API transactions**
- Dashboard shows: 2 most recent (could be mix of cached + new)
- Transaction history shows: All transactions merged

**Scenario 3: 1 cached transaction**
- Dashboard shows: 1 transaction
- Transaction history shows: 1 transaction

## 📱 User Experience

1. **App opens** → Shows 2 most recent cached transactions instantly
2. **API loads** → Updates with 2 most recent (cached + fresh merged)
3. **Pull refresh** → Always shows 2 most recent after refresh

The dashboard will always prioritize showing the 2 most recent transactions for a clean, focused view, while the full transaction history page shows all available transactions.
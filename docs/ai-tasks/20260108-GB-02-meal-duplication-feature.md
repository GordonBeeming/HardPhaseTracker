# Meal Duplication Feature

**Date:** 2026-01-08  
**Author:** GB (Gordon Beeming)  
**Task:** Add ability to duplicate meal templates

## Overview

Added meal duplication functionality that allows users to quickly create a new meal based on an existing one. The duplicate opens in the editor without saving, with " copy" appended to the name.

## Implementation

### User Actions

1. **From Meal Detail View:**
   - Tap the menu button (•••) in the top-right
   - Select "Duplicate"
   - Meal editor opens with copied data

2. **From Meals List:**
   - Swipe left on any meal
   - Tap the blue "Duplicate" button
   - Meal editor opens with copied data

### Behavior

- **Name:** Original name + " copy" (e.g., "Breakfast" → "Breakfast copy")
- **All fields copied:**
  - Protein, carbs, fats
  - Electrolyte flag
  - All components with amounts and units
- **Not saved automatically** - user must tap "Save" to persist
- **Creates new meal** - doesn't affect the original

## Technical Details

### Modified Files

1. **MealTemplateDetailView.swift**
   - Changed "Edit" button to menu with "Edit" and "Duplicate" options
   - Added `isDuplicating` state
   - Added sheet for duplicate editor

2. **MealsView.swift**
   - Added swipe action on leading edge
   - Added `isDuplicating` and `templateToDuplicate` state
   - Added sheet for duplicate editor

3. **MealTemplateEditorView.swift**
   - Added `duplicateFrom` parameter to `init()`
   - When `duplicateFrom` is provided:
     - `templateToEdit` remains `nil` (creates new meal)
     - Name gets " copy" appended
     - All other data copied from source template
   - Duplication doesn't trigger the "used in X meals" warning

### Code Flow

```
User taps Duplicate
   ↓
MealTemplateEditorView(duplicateFrom: template)
   ↓
init() receives duplicateFrom parameter
   ↓
• templateToEdit = nil (new meal, not editing)
• name = template.name + " copy"
• protein/carbs/fats/isElectrolyte = from template
• components = copy of template.componentsList
   ↓
Editor opens with pre-filled data
   ↓
User can modify as needed
   ↓
User taps "Save" → creates new meal template
```

### Design Decisions

1. **Swipe direction:** Leading edge (left swipe) - less destructive than trailing edge where delete lives
2. **Color:** Blue - indicates a copy/create action (not destructive)
3. **No auto-save:** Allows user to modify before committing
4. **Name suffix:** " copy" is clear and follows common conventions
5. **Menu in detail view:** Allows access to both Edit and Duplicate actions

## Testing Notes

### Test Cases

- [ ] Duplicate from list swipe action
- [ ] Duplicate from detail view menu
- [ ] Verify name has " copy" appended
- [ ] Verify all fields copied correctly
- [ ] Verify components copied with correct amounts/units
- [ ] Verify electrolyte flag copied
- [ ] Cancel without saving → no new meal created
- [ ] Save → new meal appears in list
- [ ] Original meal unchanged after duplication
- [ ] Can duplicate a duplicated meal (e.g., "Meal copy copy")

### Edge Cases

- [ ] Duplicate meal with no components
- [ ] Duplicate electrolyte template
- [ ] Duplicate meal with empty fields
- [ ] Duplicate meal with many components

## Future Enhancements

1. Consider adding "Duplicate" to context menu (long-press)
2. Consider allowing custom suffix (e.g., "Morning version")
3. Consider "Save as..." option when editing (creates copy with new name)
4. Consider bulk duplicate (select multiple meals)

## Related Files

- `HardPhaseTracker/Features/Meals/MealTemplateDetailView.swift`
- `HardPhaseTracker/Features/Meals/MealTemplateEditorView.swift`
- `HardPhaseTracker/Features/Meals/MealsView.swift`

## Navigation Fix

### Issue: After duplicating from list, user remained on original meal

**Problem:** When duplicating a meal via swipe action, the duplicate was created but the detail view still showed the original meal instead of the newly created duplicate.

**Solution:** 
1. Added `onSave` callback to `MealTemplateEditorView` that passes back the saved template
2. Updated both `saveUpdatingExisting()` and `saveAsNewTemplate()` to return the saved `MealTemplate`
3. Changed `MealsView` to use selection binding with `NavigationSplitView`
4. When duplicate is saved, callback updates `selectedTemplate` to the new duplicate

**Code changes:**
- `MealTemplateEditorView`: Added `onSave: ((MealTemplate) -> Void)?` parameter
- `MealTemplateEditorView`: Save functions now return `MealTemplate`
- `MealsView`: Added `@State private var selectedTemplate: MealTemplate?`
- `MealsView`: Uses `List(selection: $selectedTemplate)` with `NavigationLink(value:)`
- `MealsView`: Duplicate sheet passes callback that sets `selectedTemplate = savedTemplate`

**Result:** After duplicating from list, user is automatically navigated to the new duplicate meal. ✅

**Note:** Duplication from detail view menu still keeps you on the original (by design, as there's no parent navigation context to update).

## Navigation Fix v2 - Timing Issue

### Issue: Selection still showed original after duplicate

**Problem:** The first fix updated selection in the callback, but this happened while the sheet was still animating/dismissing, causing a race condition.

**Solution:** Use sheet's `onDismiss` closure to update selection **after** the sheet animation completes.

**Implementation:**
```swift
// Added intermediate state
@State private var templateToNavigateTo: MealTemplate?

// Sheet with onDismiss
.sheet(isPresented: $isDuplicating) {
    // This runs AFTER sheet fully dismisses
    if let template = templateToNavigateTo {
        selectedTemplate = template
        templateToNavigateTo = nil
    }
} content: {
    MealTemplateEditorView(duplicateFrom: template) { savedTemplate in
        // Store for later, don't navigate yet
        templateToNavigateTo = savedTemplate
    }
}
```

**Flow:**
1. User swipes → Duplicate
2. Editor opens with copied data
3. User saves → `templateToNavigateTo` = new duplicate
4. Sheet dismisses
 `selectedTemplate` = duplicate
6. ✅ Detail view updates to show duplicate!

**Result:** Navigation to duplicate now works reliably. 🎉

# MainScreen Component Documentation

## Overview

The `MainScreen` component is a configurable main application screen with role-based BottomNavBar that provides a consistent navigation experience across different user roles in the CareConnect application.

## Features

- **Role-based Navigation**: Different navigation items based on user role (Patient, Caregiver, Family Member, Admin)
- **Configurable**: Highly customizable through `MainScreenConfig`
- **Responsive**: Adapts to different screen sizes and platforms
- **Smooth Animations**: Configurable page transitions between tabs
- **Theme Support**: Integrates with app theming system
- **Extension Methods**: Easy navigation helpers

## Core Components

### 1. MainScreen
The main container component that renders the entire screen with bottom navigation.

### 2. BottomNavConfig
Defines navigation items for different user roles.

### 3. MainScreenConfig
Configuration class for customizing the MainScreen appearance and behavior.

## Basic Usage

```dart
// Simple usage with automatic role detection
const MainScreen()

// With specific role
MainScreen(userRole: 'PATIENT')

// With configuration
MainScreen(
  config: MainScreenConfig.forPatient(
    patientId: 123,
    primaryColor: Colors.blue,
  ),
)
```

## Configuration Options

### MainScreenConfig Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `userRole` | `String` | Required | User role (PATIENT, CAREGIVER, FAMILY_LINK, ADMIN) |
| `patientId` | `int?` | `null` | Patient ID for patient-specific screens |
| `caregiverId` | `int?` | `null` | Caregiver ID for caregiver-specific screens |
| `customNavItems` | `List<BottomNavItem>?` | `null` | Override default navigation items |
| `primaryColor` | `Color?` | `null` | Custom primary color for theme |
| `backgroundColor` | `Color?` | `null` | Custom background color |
| `enablePageAnimation` | `bool` | `true` | Enable/disable page transition animations |
| `animationDuration` | `Duration` | `300ms` | Animation duration for page transitions |
| `animationCurve` | `Curve` | `Curves.easeInOut` | Animation curve for transitions |
| `showAppBar` | `bool` | `false` | Show/hide app bar |
| `appBarTitle` | `String?` | `null` | Custom app bar title |
| `appBarActions` | `List<Widget>?` | `null` | Custom app bar actions |

## Role-based Navigation

### Patient Navigation
- **Home**: Patient dashboard with health overview
- **Health**: Health tracking and metrics
- **Messages**: Communication with care team
- **Profile**: User profile and settings

### Caregiver Navigation
- **Patients**: List of assigned patients
- **Tasks**: Task management and assignment
- **Analytics**: Patient analytics and reports
- **Messages**: Communication hub
- **Profile**: Caregiver profile and settings

## Factory Constructors

### For Patient
```dart
MainScreenConfig.forPatient(
  patientId: 123,
  primaryColor: Colors.blue,
)
```

### For Caregiver
```dart
MainScreenConfig.forCaregiver(
  caregiverId: 456,
  patientId: 789, // optional
  primaryColor: Colors.green,
)
```

### For Family Member
```dart
MainScreenConfig.forFamilyMember(
  patientId: 123,
  primaryColor: Colors.purple,
)
```

## Custom Navigation Items

You can create custom navigation items for specific use cases:

```dart
final customNavItems = [
  BottomNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    routeName: 'dashboard',
    screen: CustomDashboard(),
  ),
  BottomNavItem(
    label: 'Reports',
    icon: Icons.assessment_outlined,
    activeIcon: Icons.assessment,
    routeName: 'reports',
    screen: CustomReports(),
  ),
];

final config = MainScreenConfig(
  userRole: 'ADMIN',
  customNavItems: customNavItems,
);
```

## Navigation Helpers

### Extension Methods

The component provides convenient extension methods for navigation:

```dart
// Basic navigation
context.navigateToMainScreen(
  tabIndex: 1,
  role: 'PATIENT',
  patientId: 123,
);

// With full configuration
context.navigateToMainScreenWithConfig(
  MainScreenConfig.forCaregiver(caregiverId: 456),
  tabIndex: 2,
);
```

## Integration Examples

### From Login Screen
```dart
// After successful login
final userRole = userProvider.user?.role;
final patientId = userProvider.user?.patientId;

context.navigateToMainScreen(
  role: userRole,
  patientId: patientId,
);
```

### From Router
```dart
// In app_router.dart
GoRoute(
  path: '/main',
  builder: (context, state) {
    final role = state.extra as String?;
    return MainScreen(userRole: role);
  },
),
```

## Customization Examples

### Admin Dashboard
```dart
final adminConfig = MainScreenConfig(
  userRole: 'ADMIN',
  primaryColor: Colors.red,
  showAppBar: true,
  appBarTitle: 'Admin Dashboard',
  appBarActions: [
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => Navigator.pushNamed(context, '/admin-settings'),
    ),
  ],
);
```

### Family Member with Restricted Access
```dart
final familyConfig = MainScreenConfig.forFamilyMember(
  patientId: 123,
  customNavItems: [
    BottomNavItem(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      routeName: 'overview',
      screen: FamilyOverviewTab(),
    ),
    BottomNavItem(
      label: 'Emergency',
      icon: Icons.emergency_outlined,
      routeName: 'emergency',
      screen: EmergencyContactsTab(),
    ),
  ],
);
```

## File Structure

```
lib/
├── screens/
│   ├── main_screen.dart              # Main screen component
│   └── tabs/
│       ├── patient_tabs.dart         # Patient-specific tab implementations
│       └── caregiver_tabs.dart       # Caregiver-specific tab implementations
├── config/
│   └── navigation/
│       ├── bottom_nav_config.dart    # Navigation configuration
│       └── main_screen_config.dart   # Main screen configuration
└── examples/
    └── main_screen_usage_examples.dart # Usage examples
```

## Best Practices

1. **Use Factory Constructors**: Prefer `MainScreenConfig.forPatient()` over manual configuration
2. **Role Validation**: Always validate user roles before navigation
3. **Consistent Theming**: Use consistent colors across your app
4. **Performance**: Disable animations on lower-end devices if needed
5. **Accessibility**: Ensure navigation items have proper labels and semantics

## Migration Guide

If you're migrating from existing dashboard components:

1. Replace individual dashboard screens with `MainScreen`
2. Move tab content to appropriate tab implementation files
3. Update navigation calls to use the new extension methods
4. Configure roles and permissions through `MainScreenConfig`

## Error Handling

The component handles common error scenarios:

- **Invalid Role**: Defaults to patient navigation
- **Missing User Data**: Uses fallback values
- **Index Out of Bounds**: Resets to first tab

## Performance Considerations

- **Lazy Loading**: Tab content is only built when accessed
- **Memory Management**: PageController is properly disposed
- **Animation Optimization**: Can be disabled for better performance
- **Provider Optimization**: Uses Consumer for efficient rebuilds
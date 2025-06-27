# Payment and Access Control System Implementation

## Overview
This document outlines the implementation of a comprehensive payment and access control system for the Flutter classes app. The system allows students to pay class fees for specific months, grades, and subjects, then grants them access to online resources based on their payments.

## Firestore Database Structure

### 1. Collections

#### `payments` Collection
Stores payment transaction records:
```json
{
  "id": "payment_id",
  "userId": "user_id",
  "grade": "Grade 10",
  "subject": "Mathematics",
  "month": "January",
  "year": 2024,
  "amount": 50.0,
  "status": "completed", // pending, completed, failed
  "createdAt": "timestamp",
  "completedAt": "timestamp"
}
```

#### `subscriptions` Collection
Stores active subscriptions with access details:
```json
{
  "id": "subscription_id",
  "userId": "user_id",
  "grade": "Grade 10",
  "subject": "Mathematics",
  "month": "January",
  "year": 2024,
  "startDate": "timestamp",
  "endDate": "timestamp",
  "isActive": true,
  "paymentId": "payment_id"
}
```

#### `user_profiles` Collection
Stores extended user information:
```json
{
  "id": "user_id",
  "email": "student@example.com",
  "name": "John Doe",
  "grade": "Grade 10",
  "subjects": ["Mathematics", "Science"],
  "activeSubscriptions": ["subscription_id_1", "subscription_id_2"],
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp"
}
```

#### `resources` Collection (Enhanced)
Stores resources with access control:
```json
{
  "id": "resource_id",
  "title": "Algebra Basics",
  "description": "Introduction to algebraic concepts",
  "type": "video", // video, note, zoom_link
  "grade": "Grade 10",
  "subject": "Mathematics",
  "month": "January",
  "year": 2024,
  "url": "https://youtube.com/watch?v=...",
  "thumbnail": "https://...",
  "requiresPayment": true,
  "accessLevel": "paid" // free, paid
}
```

## Implementation Details

### 1. Domain Layer

#### Entities
- **Payment**: Represents a payment transaction
- **Subscription**: Represents an active subscription
- **UserProfile**: Extended user information with payment status

#### Use Cases
- **CreatePayment**: Creates a new payment and subscription
- **CheckAccess**: Verifies if a user has access to specific resources

### 2. Data Layer

#### Models
- **PaymentModel**: Firestore serialization for payments
- **SubscriptionModel**: Firestore serialization for subscriptions
- **UserProfileModel**: Firestore serialization for user profiles

#### Data Sources
- **PaymentRemoteDataSource**: Handles all Firestore operations for payments

#### Repositories
- **PaymentRepository**: Business logic for payment operations

### 3. Presentation Layer

#### BLoC
- **PaymentBloc**: Manages payment state and business logic

#### UI
- **PaymentPage**: User interface for making payments

## Key Features

### 1. Payment Flow
1. User selects grade, subject, month, and year
2. System shows payment summary with amount ($50.00)
3. User confirms payment
4. System creates payment record and subscription
5. User gains access to resources for that period

### 2. Access Control
- Resources are filtered based on user's active subscriptions
- Access is checked by grade, subject, month, and year
- Free resources remain accessible to all users
- Paid resources require valid subscription

### 3. Subscription Management
- Subscriptions are automatically created upon successful payment
- Each subscription covers one month for a specific grade and subject
- Subscriptions can be active or inactive
- System checks subscription validity before granting access

## Usage Examples

### Making a Payment
```dart
// Navigate to payment page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentPage(userId: currentUserId),
  ),
);
```

### Checking Access
```dart
// Check if user has access to specific resources
final hasAccess = await checkAccess(
  CheckAccessParams(
    userId: userId,
    grade: 'Grade 10',
    subject: 'Mathematics',
    month: 'January',
    year: 2024,
  ),
);
```

### Filtering Resources
```dart
// Filter videos based on user's subscriptions
final accessibleVideos = videos.where((video) {
  return video.accessLevel == 'free' || 
         userSubscriptions.any((sub) => 
           sub.grade == video.grade && 
           sub.subject == video.subject &&
           sub.month == video.month &&
           sub.year == video.year
         );
}).toList();
```

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read their own payments
    match /payments/{paymentId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Users can only read their own subscriptions
    match /subscriptions/{subscriptionId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Users can only read/write their own profile
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // Resources are readable by all authenticated users
    match /resources/{resourceId} {
      allow read: if request.auth != null;
    }
  }
}
```

## Future Enhancements

1. **Payment Gateway Integration**: Integrate with Stripe, PayPal, or local payment gateways
2. **Subscription Renewal**: Automatic renewal notifications and processing
3. **Bulk Payments**: Allow payment for multiple months/subjects at once
4. **Discount System**: Implement student discounts and promotional codes
5. **Payment History**: Detailed payment history and receipts
6. **Admin Panel**: Admin interface for managing payments and subscriptions
7. **Analytics**: Payment analytics and revenue tracking

## Testing

### Unit Tests
- Test payment creation logic
- Test access control logic
- Test subscription validation

### Integration Tests
- Test Firestore operations
- Test payment flow end-to-end
- Test access control with real data

### UI Tests
- Test payment page interactions
- Test access control UI behavior
- Test error handling and user feedback

## Deployment Considerations

1. **Environment Variables**: Store payment gateway credentials securely
2. **Error Handling**: Implement comprehensive error handling for payment failures
3. **Logging**: Log all payment transactions for audit purposes
4. **Backup**: Regular backup of payment and subscription data
5. **Monitoring**: Monitor payment success rates and system performance
6. **Compliance**: Ensure compliance with local payment regulations

This implementation provides a robust foundation for a payment and access control system that can scale with your application's needs. 
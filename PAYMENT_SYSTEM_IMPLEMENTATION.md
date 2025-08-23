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
    builder: (context) => PaymentPage(userId: currentUserId, teacherId: currentTeacherId),
  ),
);
```

### Checking Access
```
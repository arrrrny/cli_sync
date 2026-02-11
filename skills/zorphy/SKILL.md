---
name: zorphy
description: Generate Clean Architecture entities using Zorphy with support for polymorphism, factory patterns, nested objects, generics, JSON serialization, and type-safe filtering
version: 1.0.0
author: cli_sync
---

# Zorphy Entity Generation

## Overview
This skill generates Clean Architecture entities using Zorphy annotation library. It provides patterns for polymorphism (sealed/non-sealed), factory constructors, nested objects, generic types, JSON serialization with type discriminators, and type-safe filtering.

## Key Concepts

### Naming Conventions
- `$` prefix: Regular abstract class (e.g., `$User`)
- `$$` prefix: Sealed abstract class for polymorphism (e.g., `$$PaymentMethod`)

### Common Parameters
- `generateJson: true`: Enable JSON serialization
- `generateCompareTo: true`: Enable object comparison
- `generateFilter: true`: Enable filter object generation for type-safe filtering
- `explicitSubTypes`: Define polymorphic subtypes
- `nonSealed: true`: Allow runtime addition of subtypes

## Quick Start

```bash
dart run zorphy create --name User --output lib/src/domain/entities
```

## Basic Entity

```dart
@Zorphy()
abstract class $User {
  String get id;
  String get name;
  int get age;
  String? get email;
}

// Usage
final user = User(id: '1', name: 'Alice', age: 30);
final updated = user.copyWith(name: 'Bob');
```

## Polymorphic Patterns

### Sealed Classes

```dart
@Zorphy(
  generateJson: true,
  explicitSubTypes: [$CreditCard, $PayPal, $BankTransfer],
)
abstract class $$PaymentMethod {
  String get displayName;
  double get amount;
}

@Zorphy(generateJson: true)
abstract class $CreditCard implements $$PaymentMethod {
  String get cardNumber;
  String get expiryDate;
  @override String get displayName => 'Credit Card';
}

// Type-safe switch
switch (method) {
  case CreditCard cc: print('Card: ${cc.cardNumber}');
  case PayPal pp: print('PayPal: ${pp.email}');
  case BankTransfer bt: print('Bank: ${bt.bankName}');
}
```

### Non-Sealed Polymorphism

```dart
@Zorphy(
  generateJson: true,
  explicitSubTypes: [$FileAttachment, $LinkAttachment],
  nonSealed: true,
)
abstract class $$Attachment {
  String get name;
  String get mimeType;
}
```

## Factory Pattern

```dart
@Zorphy()
abstract class $Order {
  String get orderId;
  String get customerId;
  List<$OrderItem> get items;
  double get total;

  static Order create({
    required String customerId,
    required List<$OrderItem> items,
  }) {
    final total = items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
    return Order(
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      items: items,
      total: total,
    );
  }
}

// Usage
final order = Order.create(customerId: 'cust_123', items: [...]);
```

## Nested Objects

```dart
@Zorphy()
abstract class $Address {
  String get street;
  String get city;
  String get state;
  String get zipCode;
}

@Zorphy()
abstract class $Person {
  String get name;
  int get age;
  $Address get address;
}

// Nested patching
final patched = person.patchWithPerson(
  patchInput: PersonPatch.create()
    ..withAddressPatch(
      AddressPatch.create()..withCity('Los Angeles'),
    ),
);
```

### Self-Referencing (Trees)

```dart
@Zorphy(generateJson: true)
abstract class $CategoryNode {
  String get id;
  String get name;
  List<$CategoryNode>? get children;
  $CategoryNode? get parent;
}
```

## Generic Types

```dart
@Zorphy(generateJson: true)
abstract class $Result<T> {
  bool get success;
  T? get data;
  String? get errorMessage;
}

// Usage
final stringResult = Result<String>(success: true, data: 'Hello');
final intResult = Result<int>(success: true, data: 42);
```

### Multiple Type Parameters

```dart
@Zorphy(generateJson: true)
abstract class $KeyValue<K, V> {
  K get key;
  V get value;
}
```

## JSON Serialization

```dart
@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
  DateTime get createdAt;
}

// Serialize
final json = product.toJson();

// Deserialize
final restored = Product.fromJson(json);

// Lean JSON (excludes metadata)
final leanJson = product.toJsonLean();
```

### Polymorphic JSON

```dart
// JSON includes "_className_" discriminator
final json = creditCard.toJson();
// { "_className_": "CreditCard", "cardNumber": "...", ... }

// Automatic deserialization
final restored = PaymentMethod.fromJson(json);
print(restored.runtimeType); // CreditCard
```

## Patching

```dart
final patch = UserPatch.create()
  ..withName('Alice Smith')
  ..withAge(31);

final patched = user.patchWithUser(patchInput: patch);
```

## Filtering

```dart
@Zorphy(generateFilter: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
  String? get category;
  bool get inStock;
}

// Create filter
final filter = ProductFilter.create()
  ..withCategory('Electronics')
  ..withInStock(true)
  ..withPriceRange(min: 10.0, max: 100.0);

// Use in repository
final products = await productRepository.getList(filter: filter);

// Chain filters
final complexFilter = ProductFilter.create()
  ..withCategory('Electronics')
  ..withInStock(true)
  ..withNameContains('Phone');

// Check if filter is empty
if (filter.isEmpty) {
  // No filters applied
}

// Combine filters
final combined = filter1.merge(filter2);
```

### Filter Types Generated

- `with<Field>(value)`: Exact match
- `with<Field>In(values)`: Match any in list
- `with<Field>Contains(text)`: String contains
- `with<Field>StartsWith(text)`: String starts with
- `with<Field>EndsWith(text)`: String ends with
- `with<Field>Range(min, max)`: Numeric/date range
- `with<Field>GreaterThan(value)`: Greater than
- `with<Field>LessThan(value)`: Less than
- `with<Field>IsNull()`: Is null
- `with<Field>IsNotNull()`: Is not null

## Multiple Inheritance

```dart
@Zorphy()
abstract class $Timestamped {
  DateTime get createdAt;
  DateTime? get updatedAt;
}

@Zorphy()
abstract class $Identified {
  String get id;
}

@Zorphy()
abstract class $Post implements $Timestamped, $Identified {
  String get title;
  String get content;
}
```

## Enums

```dart
enum UserStatus { active, inactive, suspended }

@Zorphy(generateJson: true)
abstract class $Account {
  String get username;
  UserStatus get status;
}

// Enums serialize to strings
final json = account.toJson(); // { "status": "active", ... }
```

## ChangeTo Extension

```dart
@Zorphy(explicitSubTypes: [$Circle, $Rectangle])
abstract class $$Shape {
  String get name;
}

// Convert between subtypes
final rectangle = circle.changeToRectangle(width: 10.0, height: 15.0);
```

## CompareTo

```dart
@Zorphy(generateCompareTo: true, generateJson: true)
abstract class $Document {
  String get title;
  String get content;
  int get version;
}

final diff = doc1.compareToDocument(doc2); // Map of changed fields
```

## Best Practices

1. Use `$$` prefix for sealed abstract classes requiring exhaustive checking
2. Use `$` prefix for regular abstract classes
3. Enable `generateJson: true` when serialization is needed
4. Enable `generateFilter: true` for entities that need type-safe filtering in queries
5. Use `explicitSubTypes` for polymorphic hierarchies
6. Use `nonSealed: true` when subtypes may be added dynamically
7. Use static factories for complex object creation
8. Use generics for reusable data structures
9. Use patching for partial updates without breaking immutability

## File Structure

```
lib/src/domain/entities/
├── user/
│   ├── user.dart
│   ├── user.zorphy.dart
│   └── user.g.dart
├── payment_method/
│   ├── payment_method.dart
│   ├── credit_card/credit_card.dart
│   ├── pay_pal/pay_pal.dart
│   └── bank_transfer/bank_transfer.dart
└── enums/
    ├── index.dart
    └── user_status.dart
```

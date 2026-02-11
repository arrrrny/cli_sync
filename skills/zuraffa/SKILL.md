---
name: zuraffa
description: Generate Clean Architecture Flutter code with Zuraffa CLI. ALWAYS use this skill when creating pages, repositories, data layers, or UseCases in Flutter projects that have zuraffa in pubspec.yaml dependencies. Provides automatic generation of Views, Presenters, Controllers, State, UseCases, Repositories, and DataSources.
version: 1.0.0
author: cli_sync
---

# Zuraffa Clean Architecture Generator

## Overview
Zuraffa is a Clean Architecture code generator for Flutter projects. It automates the creation of presentation layers (View, Presenter, Controller, State), domain layers (UseCases, Repositories), and data layers (DataRepository, DataSource) following strict Clean Architecture principles.

## When to Use This Skill

**ALWAYS use Zuraffa when:**
1. The user asks to create a new page/screen/widget
2. The user asks to create a repository
3. The user asks to create a data layer
4. The user asks to create a UseCase
5. The Flutter project has `zuraffa` in pubspec.yaml dependencies

**Check for Zuraffa first:**
```bash
grep -q "zuraffa" pubspec.yaml && echo "Use Zuraffa" || echo "Manual implementation"
```

## Quick Reference

### Create Complete Feature (Recommended)
```bash
zuraffa generate --name Product --vpc --state --data --methods get,getList,create,update,delete
```

### Create Presentation Layer Only
```bash
zuraffa generate --name ProductList --vpc --state
```

### Create UseCase with Repository
```bash
zuraffa generate --name GetProducts --repo ProductRepository --returns List<Product>
```

### Create Data Layer Only
```bash
zuraffa generate --name Product --data --methods get,getList,create,update,delete
```

## Common Parameters

| Parameter | Description |
|-----------|-------------|
| `--name` | Entity or UseCase name (PascalCase, required) |
| `--vpc` | Generate View, Presenter, Controller |
| `--state` | Generate State object with granular loading states |
| `--data` | Generate Data layer (DataRepository + DataSource) |
| `--methods` | CRUD methods: get, getList, create, update, delete, watch, watchList |
| `--repo` | Repository to inject (for custom UseCases) |
| `--returns` | Return type for custom UseCases |
| `--params` | Params type for custom UseCases |
| `--cache` | Enable caching with dual datasources |
| `--gql` | Generate GraphQL files |
| `--di` | Generate dependency injection files |
| `--test` | Generate unit tests |

## Entity-Based Generation (CRUD)

### Full Stack with All CRUD Operations
```bash
zuraffa generate --name Product \
  --vpc --state --data --di \
  --methods get,getList,create,update,delete
```

**Generates:**
- `lib/src/domain/entities/product/product.dart`
- `lib/src/domain/usecases/product/get_product.dart`
- `lib/src/domain/usecases/product/get_product_list.dart`
- `lib/src/domain/usecases/product/create_product.dart`
- `lib/src/domain/usecases/product/update_product.dart`
- `lib/src/domain/usecases/product/delete_product.dart`
- `lib/src/domain/repositories/product_repository.dart`
- `lib/src/data/repositories/product_data_repository.dart`
- `lib/src/data/datasources/product_remote_data_source.dart`
- `lib/src/presentation/pages/product/product_page.dart`
- `lib/src/presentation/pages/product/product_presenter.dart`
- `lib/src/presentation/pages/product/product_controller.dart`
- `lib/src/presentation/pages/product/product_state.dart`

### Read-Only Feature
```bash
zuraffa generate --name Category --vpc --state --data --methods get,getList
```

### With Caching
```bash
zuraffa generate --name Product \
  --vpc --state --data --cache \
  --methods get,getList
```

**Generates additional:**
- `lib/src/data/datasources/product_local_data_source.dart`

## Custom UseCases

### UseCase with Repository Injection
```bash
zuraffa generate --name ProcessPayment \
  --repo PaymentRepository \
  --returns PaymentResult \
  --params ProcessPaymentParams
```

### UseCase with Service Injection
```bash
zuraffa generate --name SendEmail \
  --service EmailService \
  --returns void \
  --params SendEmailParams
```

### UseCase Types
```bash
# Regular async UseCase (default)
zuraffa generate --name FetchData --returns Data

# Stream UseCase
zuraffa generate --name WatchMessages --type stream --returns Stream<Message>

# Background UseCase
zuraffa generate --name SyncData --type background

# Completable UseCase (no return)
zuraffa generate --name LogEvent --type completable

# Sync UseCase
zuraffa generate --name CalculateTotal --type sync --returns double
```

## Presentation Layer Options

### Full VPC with State
```bash
zuraffa generate --name ProductDetail --vpc --state
```

**State includes granular loading states:**
- `isGetting` / `isGettingList`
- `isCreating` / `isUpdating` / `isDeleting`
- `isWatching` / `isWatchingList`
- `error` / `hasError`
- Entity-specific state fields

### VPC Without State (Custom Controller)
```bash
zuraffa generate --name CustomWidget --vpc
```

### Presenter + Controller Only (Preserve Custom View)
```bash
zuraffa generate --name ProductList --pc
```

### Presenter + Controller + State (Preserve Custom View)
```bash
zuraffa generate --name ProductList --pcs
```

## Data Layer Options

### With GraphQL
```bash
zuraffa generate --name Product \
  --data --gql \
  --methods get,getList,create,update,delete
```

**Generates additional:**
- `lib/src/graphql/queries/product.graphql`
- `lib/src/graphql/mutations/product.graphql`

### With Mock Data
```bash
zuraffa generate --name Product --data --mock
```

### Append to Existing Repository
```bash
zuraffa generate --name GetSpecialProducts \
  --repo ProductRepository \
  --append
```

## GraphQL Integration

### Import from GraphQL Schema
```bash
zuraffa graphql --url https://api.example.com/graphql \
  --entities Product,Category,Order \
  --methods get,getList,create,update,delete \
  --data --vpc --state
```

### Import Specific Queries/Mutations
```bash
zuraffa graphql --url https://api.example.com/graphql \
  --queries getProduct,getProductList \
  --mutations createProduct,updateProduct \
  --domain product
```

## Dependency Injection

### Generate DI Registration
```bash
zuraffa generate --name Product --vpc --state --data --di
```

**Generates:**
- `lib/src/di/product_di.dart`

### Use Mock DataSource in DI
```bash
zuraffa generate --name Product --data --di --use-mock
```

## Configuration

### Initialize Config
```bash
zuraffa config init
```

### View Config
```bash
zuraffa config show
```

### Set Config Values
```bash
zuraffa config set --key jsonByDefault --value true
zuraffa config set --key defaultEntityOutput --value lib/src/domain/entities
zuraffa config set --key gqlByDefault --value true
zuraffa config set --key diByDefault --value true
```

## Workflow Examples

### Feature-First Approach
```bash
# 1. Create entity
zuraffa entity create --name Product --fields id:String,name:String,price:double

# 2. Generate full stack
zuraffa generate --name Product \
  --vpc --state --data --di \
  --methods get,getList,create,update,delete

# 3. Run build_runner
dart run build_runner build --delete-conflicting-outputs
```

### GraphQL-First Approach
```bash
# 1. Import from schema
zuraffa graphql --url https://api.example.com/graphql \
  --entities Product,Category \
  --vpc --state --data --gql --di

# 2. Run codegen
dart run build_runner build --delete-conflicting-outputs
```

### Incremental Development
```bash
# Start with presentation
zuraffa generate --name Product --vpc --state

# Add data layer later
zuraffa generate --name Product --data --methods get,getList

# Add more methods
zuraffa generate --name Product --data --methods create,update,delete --append
```

## Best Practices

1. **Always check pubspec.yaml** for zuraffa dependency before generating code
2. **Use `--state`** for automatic state management with granular loading states
3. **Use `--di`** to generate dependency injection registration
4. **Use `--append`** when adding methods to existing repositories
5. **Use `--cache`** for offline-first features
6. **Use `--test`** to generate unit tests alongside production code
7. **Run build_runner** after generation to generate Zorphy and GraphQL code
8. **Use entity-based generation** for CRUD operations
9. **Use custom UseCases** for complex business logic

## Common Commands Reference

```bash
# Check if Zuraffa is available
grep "zuraffa" pubspec.yaml

# Full feature generation
zuraffa generate --name Feature --vpc --state --data --di --methods get,getList,create,update,delete

# Presentation only
zuraffa generate --name Feature --vpc --state

# Data layer only
zuraffa generate --name Feature --data --methods get,getList

# Custom UseCase
zuraffa generate --name Action --repo RepositoryName --returns ReturnType

# With caching
zuraffa generate --name Feature --vpc --state --data --cache

# With GraphQL
zuraffa generate --name Feature --data --gql

# Append to existing
zuraffa generate --name NewMethod --repo ExistingRepository --append
```

## Integration with Zorphy

Zuraffa uses Zorphy for entity generation. Entities created with Zuraffa automatically support:

- `copyWith()` for immutable updates
- `patchWith*()` for partial updates
- `toJson()` / `fromJson()` for serialization
- `compareTo()` for object comparison
- Polymorphism with sealed classes

See the zorphy skill for entity patterns and advanced features.

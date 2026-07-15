# Expense Management Module

## Overview
The Expense Management module handles all expense-related operations for the SplitSync application. It follows clean architecture principles with clear separation of concerns between presentation, domain, and data layers.

## Features
- ✅ **Add Expense**: Create new expenses with details (description, amount, category, tags, notes)
- ✅ **Edit Expense**: Modify existing expense details
- ✅ **Expense Detail**: View complete expense information
- ✅ **Expense History**: Browse all expenses with filtering by category
- ✅ **Delete Expense**: Remove expenses from the system

## Architecture

### Domain Layer (`domain/`)
**Entities**:
- `ExpenseEntity`: Core business entity representing an expense

**Repositories**:
- `ExpenseRepository`: Abstract interface defining repository contract

**Use Cases**:
- `CreateExpenseUseCase`: Create new expense
- `UpdateExpenseUseCase`: Update existing expense
- `DeleteExpenseUseCase`: Delete expense
- `GetExpenseUseCase`: Fetch single expense
- `GetGroupExpensesUseCase`: Fetch all expenses in a group
- `GetExpensesHistoryUseCase`: Fetch paginated expense history

### Data Layer (`data/`)
**Models**:
- `ExpenseModel`: Data transfer object with JSON serialization
- `ExpenseCategory`: Enum for expense categories (food, transport, entertainment, utilities, shopping, other)

**Data Sources**:
- `ExpenseDatasource`: Abstract interface for data operations (to be implemented with Supabase)

**Repositories**:
- `ExpenseRepositoryImpl`: Concrete implementation of `ExpenseRepository`

### Presentation Layer (`presentation/`)
**Pages**:
- `AddExpensePage`: Form to add new expense
- `EditExpensePage`: Form to edit existing expense
- `ExpenseDetailPage`: View detailed expense information
- `ExpenseHistoryPage`: List all expenses with filtering

**Features**:
- Form validation
- Category dropdown with localized labels
- Tag management system
- Date formatting utilities
- Currency formatting
- Filter by category

## Data Model

```dart
ExpenseModel {
  id: String,                           // Unique identifier
  groupId: String,                      // Associated group
  paidBy: String,                       // User ID who paid
  amount: double,                       // Amount in currency
  category: ExpenseCategory,            // Category enum
  description: String,                  // Expense description
  itemCount: int?,                      // Number of items (optional)
  tags: List<String>,                   // Tags for categorization
  note: String?,                        // Additional note
  receipt: String?,                     // Receipt image path
  ocrJobId: String?,                    // OCR job reference
  createdAt: DateTime,                  // Creation timestamp
  updatedAt: DateTime,                  // Last update timestamp
}
```

## Category Labels
| Enum Value    | Indonesian Label |
|---------------|------------------|
| food          | Makanan          |
| transport     | Transportasi     |
| entertainment | Hiburan          |
| utilities     | Utilitas         |
| shopping      | Belanja          |
| other         | Lainnya          |

## Integration Guide

### 1. Implement Supabase Datasource
Create `ExpenseDatasourceImpl` implementing `ExpenseDatasource`:

```dart
class ExpenseDatasourceImpl extends ExpenseDatasource {
  ExpenseDatasourceImpl(this.supabase);
  final SupabaseClient supabase;

  @override
  Future<ExpenseModel> createExpense({...}) async {
    // Implementation with Supabase insert
  }
  // ... implement other methods
}
```

### 2. Set Up Dependency Injection
Register the repository and use cases in your service locator:

```dart
// In your setup/injection file
final expenseDatasource = ExpenseDatasourceImpl(supabaseClient);
final expenseRepository = ExpenseRepositoryImpl(expenseDatasource);

getIt.registerSingleton<ExpenseRepository>(expenseRepository);
getIt.registerSingleton<CreateExpenseUseCase>(
  CreateExpenseUseCase(expenseRepository)
);
// ... register other use cases
```

### 3. Connect Pages to Use Cases
In your pages, inject use cases and handle the expense operations:

```dart
// Example in AddExpensePage
final createExpenseUseCase = getIt<CreateExpenseUseCase>();

void _handleSubmit() {
  final entity = await createExpenseUseCase.call(
    groupId: widget.groupId,
    paidBy: widget.userId,
    amount: double.parse(_amountController.text),
    category: _selectedCategory,
    description: _descriptionController.text,
    tags: _tags,
    note: _noteController.text,
  );
  // Navigate or show success
}
```

## UI Components

### Form Fields Available
- Description field (text input)
- Amount field (numeric input)
- Category dropdown (6 options)
- Note field (multi-line text)
- Tags system (add/remove tags)

### Styling Constants
- Primary color: `#C70F1B` (Dark Red)
- Secondary color: `#D70F1F` (Bright Red)
- Background: `#FBF7F4` (Light Beige)
- Text primary: `#111827` (Dark)
- Text secondary: `#6B7280` (Gray)

## Database Tables Required (from Backend)
The following tables should be set up in Supabase:
- `expenses` - Main expenses table
- `expense_items` - Itemized expenses (optional)
- `expense_item_participants` - Item-level split participants (optional)
- `expense_splits` - How expense is split (references to `expense_debts`)
- `expense_debts` - Debt records for settlement

## TODO - Remaining Implementation
- [ ] Implement `ExpenseDatasourceImpl` with Supabase
- [ ] Set up dependency injection
- [ ] Connect use cases to UI pages
- [ ] Add error handling and validation
- [ ] Implement pagination for history
- [ ] Add loading states and error states
- [ ] Write unit tests for use cases
- [ ] Write widget tests for pages
- [ ] Add image upload for receipts
- [ ] Integrate with OCR service for receipt scanning

## Notes
- All pages use Indonesian (Bahasa Indonesia) labels
- Currency formatting uses `$` symbol (customize as needed)
- Date formatting uses abbreviated month names
- Tags are user-defined and stored as List<String>
- Expense history supports filtering by category
- Images and receipts paths are stored, actual image handling TBD

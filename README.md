# Card Organizer App

A Flutter application for organizing playing cards into folders based on suits (Hearts, Spades, Diamonds, and Clubs). This app demonstrates SQLite database integration, CRUD operations, and modern Flutter UI design.

## Features

### Core Functionality
- **Four Pre-defined Folders**: Hearts, Spades, Diamonds, and Clubs folders
- **Card Management**: Full deck of standard playing cards (52 cards total)
- **Folder Limits**: Each folder can hold 3-6 cards with proper validation
- **CRUD Operations**: Complete Create, Read, Update, Delete functionality for both cards and folders

### Image Handling
- **Network Images**: Cards display images from deckofcardsapi.com
- **Image Caching**: Images stored as byte data in SQLite database for offline use
- **Fallback System**: Multi-tier fallback system (cache → assets → network → placeholder)
- **Image Management**: Dedicated screen for downloading and managing card images
- **Performance Optimization**: Memory caching and lazy loading for smooth performance

### User Interface
- **Folders Screen**: Grid view of all folders showing card counts and preview card images
- **Cards Screen**: Detailed view of cards within each folder with card images and add/remove functionality
- **Folder Management**: Advanced screen for creating, editing, and deleting custom folders
- **Image Management**: Screen for downloading images for offline use and cache management
- **Visual Feedback**: Color-coded status indicators and warning messages

### Database Features
- **SQLite Integration**: Local database storage for persistent data
- **Relational Design**: Proper foreign key relationships between folders and cards
- **Image Storage**: BLOB storage for card images as byte arrays
- **Data Validation**: Enforced business rules and constraints

## Database Schema

### Folders Table
- `id` (INTEGER PRIMARY KEY)
- `name` (TEXT NOT NULL)
- `suit` (TEXT NOT NULL UNIQUE)
- `timestamp` (INTEGER NOT NULL)

### Cards Table
- `id` (INTEGER PRIMARY KEY)
- `name` (TEXT NOT NULL)
- `suit` (TEXT NOT NULL)
- `value` (TEXT NOT NULL)
- `imageUrl` (TEXT NOT NULL)
- `imageData` (BLOB, for cached images)
- `folderId` (INTEGER, Foreign Key)

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd inclass11
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

### Building APK
To build an APK for Android:
```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Usage

### Main Screen (Folders)
- View all available folders in a grid layout
- Each folder shows:
  - Suit icon and name
  - Current card count
  - Color-coded status (green: 3-6 cards, orange: <3 cards, red: >6 cards)
  - Preview of the first card (if any)
- Tap any folder to view its cards
- Use the settings icon to manage folders
- Use the refresh icon to reload data

### Cards Screen
- View all cards currently in the selected folder
- Add cards from the available unassigned cards of the same suit
- Remove cards from the folder (returns them to unassigned)
- Visual status indicator showing folder capacity
- Warning displayed when leaving with <3 cards

### Folder Management Screen (Advanced)
- Create custom folders with any name and suit
- Edit existing folder names and suits
- Delete folders (moves all cards back to unassigned)
- Confirmation dialogs for destructive actions

## Business Rules

### Card Organization
- Cards can only be added to folders of the matching suit
- Each folder must contain 3-6 cards for optimal organization
- Folders with <3 cards show warning messages
- Folders with >6 cards prevent additional cards from being added

### Data Integrity
- Each card belongs to exactly one folder or remains unassigned
- Deleting a folder moves all its cards back to unassigned status
- Suit constraints ensure logical organization

## Technical Implementation

### Architecture
- **Models**: Dart classes for Folder and Card entities
- **Database**: SQLite with proper schema and relationships  
- **Screens**: Modular UI components following Flutter best practices
- **State Management**: StatefulWidget with async data loading

### Key Dependencies
- `sqflite: ^2.3.2` - SQLite database integration
- `path: ^1.8.3` - Path manipulation utilities

### Code Structure
```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── folder.dart                    # Folder model class
│   └── card.dart                      # Card model class
├── database/
│   └── database_helper.dart           # SQLite database operations
└── screens/
    ├── folders_screen.dart            # Main folders grid view
    ├── cards_screen.dart              # Card management for folders
    └── folder_management_screen.dart   # Advanced folder CRUD
```

## Future Enhancements

### Potential Features
- Card image integration with actual playing card graphics
- Search and filter functionality
- Import/export deck configurations
- Statistics and analytics
- Multiple deck support
- User profiles and preferences

### Performance Optimizations
- Lazy loading for large datasets
- Image caching for card graphics
- Database query optimization
- Background sync capabilities

## License

This project is created for educational purposes as part of a Flutter development course focusing on SQLite integration and mobile app development best practices.

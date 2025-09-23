# 🎲 Ludo Club - Premium Flutter Ludo Game

A beautiful, feature-rich Ludo (Mensch ärgere Dich nicht) game built with Flutter, featuring stunning SVG graphics, smooth animations, and complete 2-4 player support.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## ✨ Features

### 🎮 **Game Features**
- **🎯 Complete Ludo Rules Implementation**
  - Standard 52-field main path + 6-field home stretch
  - Capture opponents on non-safe fields
  - Safe fields marked with star symbols
  - Must roll 6 to start from home base
  - Extra turn on rolling 6 or capturing opponent
  - Win by getting all 4 pieces to center

- **👥 Dynamic Player Management (2-4 Players)**
  - Add/Remove players with intuitive buttons
  - Visual color indicators (🔴 Red, 🟢 Green, 🔵 Blue, 🟡 Yellow)
  - Custom player names
  - Automatic color assignment

- **🎨 Beautiful SVG Graphics**
  - Hand-crafted teardrop-shaped pins with gradients
  - Animated dice faces (1-6) with smooth rotations
  - Custom-painted game board with safe field markers
  - Responsive sizing for all screen sizes

### 🎵 **Audio & Animation**
- **🔊 Sound Effects**
  - Dice roll sound
  - Piece movement sound
  - Capture/hit sound
  - Victory celebration sound

- **🎭 Smooth Animations**
  - Dice rolling with rotation, shake, and scale effects
  - Pin movement with `AnimatedPositioned`
  - Bounce animations on pin selection
  - Hover effects and visual feedback

### 🛡️ **Game Logic**
- **⚔️ Advanced Capture System**
  - Pieces can capture opponents on main path
  - Safe fields prevent captures (positions 0, 5, 13, 18, 26, 31, 39, 44)
  - Captured pieces return to home base
  - Capturing grants extra turn

- **🏠 Home Stretch Logic**
  - Correct entry points for each player color
  - Path wrapping with modulo arithmetic
  - Prevents overshooting in home stretch
  - Win condition checking

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/leonwwest/ludo_club.git
   cd ludo_club
   ```

2. **Navigate to the Flutter project**
   ```bash
   cd ludo_club
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 🎯 How to Play

### 🏁 **Starting a Game**
1. **Launch the app** and tap "New Game"
2. **Add/Remove players** using the ➕➖ buttons (2-4 players)
3. **Enter player names** or use defaults
4. **Start playing** - Red player goes first!

### 🎲 **Game Rules**
1. **Roll dice** by tapping the dice widget
2. **Roll 6** to move pieces from home base to start field
3. **Move pieces** by tapping highlighted movable pins
4. **Capture opponents** by landing on their pieces (except safe fields ⭐)
5. **Enter home stretch** when reaching your color's entry point
6. **Win** by getting all 4 pieces to the center!

### 🛡️ **Safe Fields**
Safe fields (marked with ⭐) where pieces cannot be captured:
- **Red Start:** Field 0
- **Green Start:** Field 13  
- **Blue Start:** Field 26
- **Yellow Start:** Field 39
- **Additional Safe Fields:** 8, 21, 34, 47

## 🏗️ Technical Architecture

### 📁 **Project Structure**
```
lib/
├── logic/           # Game rules and path logic
├── models/          # Data models (GameState, Player, Piece)
├── providers/       # State management (GameProvider)
├── services/        # Audio and game services
├── ui/             # Screen widgets
└── widgets/        # Reusable UI components

assets/
├── audio/          # Sound effects (MP3)
├── board/          # Board background
├── dice/           # Dice SVG assets (1-6)
└── pins/           # Player pin SVGs (4 colors)
```

### 🧩 **Key Components**

#### **State Management**
- `GameProvider` with `ChangeNotifier` for reactive UI
- Centralized game state with immutable updates
- Audio service integration

#### **Custom Widgets**
- `LudoPin`: Animated SVG pins with hover effects
- `DiceWidget`: Animated dice with roll simulation
- `LudoBoardPainter`: Custom-painted game board
- `BoardWidget`: Main game board with piece positioning

#### **Game Logic**
- `LudoGame`: Core rule implementation
- Path calculation with modulo arithmetic
- Movement validation and capture detection
- Win condition checking

## 🎨 Design Features

### 🎯 **Visual Design**
- **Modern UI** with gradient backgrounds
- **Responsive layout** for all screen sizes
- **Intuitive controls** with visual feedback
- **Color-coded players** with clear identification

### 🎪 **Animations**
- **Dice Rolling:** 3D rotation with shake effect
- **Pin Movement:** Smooth position transitions
- **Selection Feedback:** Scale and glow effects
- **Turn Indicators:** Clear current player display

## 🛠️ Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.0.5         # State management
  flutter_svg: ^2.0.7     # SVG asset support
  just_audio: ^0.9.34     # Audio playback
  
dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^2.0.0
```

## 🎮 Game Features in Detail

### 🎯 **Pin Movement System**
- **Teardrop-shaped SVG pins** with ID overlays
- **Animated movement** with `AnimatedPositioned`
- **Visual highlighting** for movable pieces
- **Responsive sizing** based on board dimensions

### 🎲 **Advanced Dice System**
- **Realistic roll animation** (rotation + shake)
- **Random value generation** with visual feedback
- **Disabled state** when not player's turn
- **Audio feedback** on each roll

### 🏆 **Win Conditions**
- **All 4 pieces in center** to win
- **Turn order maintained** throughout game
- **Game over detection** with winner announcement
- **New game option** to restart

## 🔧 Development

### 🐛 **Debugging**
The game includes extensive logging for debugging:
- Piece movement validation
- Capture detection
- Turn management
- Audio playback

### 🧪 **Testing**
```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (Ubuntu 18.04+)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- SVG assets created with custom gradients and shadows
- Audio assets optimized for cross-platform playback
- Ludo game rules based on traditional "Mensch ärgere Dich nicht"

## 📞 Support

If you have any questions or need help, please:
- 🐛 [Open an issue](https://github.com/leonwwest/ludo_club/issues)
- 💬 [Start a discussion](https://github.com/leonwwest/ludo_club/discussions)
- 📧 Contact: [your-email@example.com]

---

**Made with ❤️ using Flutter** 

*Enjoy playing Ludo Club with friends and family!* 🎉

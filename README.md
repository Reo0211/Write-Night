# Write Night 🌌
"Turn your thoughts into stars and build your own universe."

Developed during my study abroad at The Chinese University of Hong Kong.  
Write Night is a healing journaling app that transforms your daily reflections into a mesmerizing, ever-expanding galaxy. Built entirely with SwiftUI, it focuses on turning the solitary act of writing into a poetic visual experience.

---

##  Technical Highlights

### 1. Dynamic Generative Visuals (SwiftUI & Animation)
 # Developed a custom star-rendering system where each journal entry is mapped to a unique star with specific coordinates and colors.
 # Complex Motion Graphics: Leveraged `TimelineView` and `withAnimation` to create seamless parallax effects and fluid starfield transitions, ensuring a high-performance visual experience even with hundreds of on-screen elements.
 # Hierarchical State Management: Utilized `@StateObject` and `@EnvironmentObject` to synchronize the app’s state (Sky, Planets, and Memos) across a multi-layered ZStack architecture.

### 2. Event-Driven Architecture
 # Decoupled Interaction Logic: Implemented a robust event system using `NotificationCenter` to handle complex triggers like "Moon Shaking" (haptic interaction) and "Comet Appearances" without creating tight coupling between UI components.
 # Modular MVVM Pattern: Separated concerns into distinct ViewModels (`Memo`, `Sky`, `Planet`, `MemoryPlanet`), ensuring the codebase remains maintainable and scalable.

### 3. Sensory User Experience (UX & CoreMotion)
 # Physicality in Digital Space: Integrated `CoreMotion` (Gyroscope) and `Haptics` to provide tactile feedback, giving the digital universe a sense of weight and presence.
 # Deadline Monitoring System: Engineered a background monitoring logic (`startDeadlineMonitoring`) that tracks the "phases of the moon" for each entry, triggering dynamic UI updates based on time progression.

### 4. Adaptive & Scalable Design
 Universal Layout: Designed and optimized for both iPhone and iPad, utilizing adaptive layouts to maintain the "vastness" of the night sky across different screen aspect ratios.

---

## 📖 Background & Philosophy
As an exchange student in Hong Kong, I wanted to create a tool that could transform the feeling of late-night solitude into something beautiful. 
In this app, technology serves as a bridge between raw emotion and artistic expression. By leveraging the declarative nature of SwiftUI, 
I aimed to push the boundaries of what a "simple utility" can look and feel like.

---

## 🛠 Tech Stack
- Language: Swift
- Framework: SwiftUI
- Concurrency: Swift Concurrency (Async/Await)
- Data: SwiftData / UserDefaults
- Tools: Xcode, Figma, Git

---
© 2026 Reoto Ando. All rights reserved.

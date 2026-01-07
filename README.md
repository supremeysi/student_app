# Student Notes & Task Manager (Shiny App)

A feature-rich, interactive, and aesthetically pleasing Dashboard designed for students to manage their academic life efficiently. Built using **R Shiny**, this application integrates task management, scheduling, and real-time alerts with a delightful "girly-themed" user interface.

## Key Features
* **Interactive Calendar:** A visual overview of tasks and deadlines powered by FullCalendar JS integration.
* **Real-time Notifications:** Includes a notification bell system with audio alerts for upcoming deadlines.
* **Progress Tracking:** A dynamic progress bar that calculates and displays your task completion rate in real-time.
* **Archive System:** Securely move completed or long-term tasks to an **Archive** folder to keep your main board clean.
* **Smart Trash Management:** - Notes moved to **Trash** are automatically tracked.
  - Features a precise **Philippine Time (UTC+8)** timestamp using SQLite `localtime` modifiers.
* **Responsive Aesthetic:** Soft pink theme featuring animated bunny characters for a friendly and motivating user experience.

## Tech Stack
* **Language:** R
* **Framework:** Shiny, ShinyModules
* **Database:** SQLite (managed via `pool` and `DBI` for stability)
* **Frontend:** HTML5, CSS3, JavaScript, FullCalendar JS, Canvas-confetti
* **Timezone Handling:** Optimized for Manila Time (UTC+8) using database-level `localtime` conversion.

## How to Run Locally
1. Clone this repository:
   ```bash
   git clone [https://github.com/supremeysi/student_app.git](https://github.com/supremeysi/student_app.git)

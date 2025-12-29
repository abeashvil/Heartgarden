# 🌸 Couples Flower Care App — Requirements Document

---

## 1. App Overview

This app is a sweet game for couples.  
Both people care for a shared flower every day.  
To care for the flower, each person answers one daily question and sends one photo to the other.  
If both people do their part, the flower stays happy and grows.  
Over time, couples can collect many flowers and see them all in a garden.

---

## 2. Main Goals

1. Help couples connect every day in a fun way.  
2. Encourage daily habits with questions and photos.  
3. Let users grow and collect flowers together.  
4. Make the app simple and calm to use.

---

## 3. User Stories

- **US-001**: As a user, I want to see my flower when I open the app so that I feel connected right away.  
- **US-002**: As a user, I want to tap the flower so that I can answer today’s question.  
- **US-003**: As a user, I want to send a photo to my partner so that we share part of our day.  
- **US-004**: As a user, I want to see if my partner has completed today’s task so that I know we’re in sync.  
- **US-005**: As a user, I want to collect many flowers so that our progress feels rewarding.  
- **US-006**: As a user, I want to view all my flowers in one place so that I can see our garden.

---

## 4. Features

- **F-001: Daily Flower Display**  
  - What it does: Shows the current flower on the main screen.  
  - When it appears: Every time the app opens.  
  - If something goes wrong: Show a message like “Flower not loaded. Try again.”

- **F-002: Daily Question**  
  - What it does: Shows one question linked to the flower for that day.  
  - When it appears: After tapping the flower.  
  - If something goes wrong: Show a simple backup question.

- **F-003: Photo Sending**  
  - What it does: Lets the user take or pick one photo and send it.  
  - When it appears: After answering the question.  
  - If something goes wrong: Tell the user the photo was not sent and let them try again.

- **F-004: Partner Status**  
  - What it does: Shows if the partner has completed today’s care.  
  - When it appears: On the flower screen.  
  - If something goes wrong: Show “Waiting for partner.”

- **F-005: Streak Tracking**  
  - What it does: Counts how many days in a row both users care for the flower.  
  - When it appears: On the main screen or garden view.  
  - If something goes wrong: Reset only if a day is missed.

- **F-006: Flower Collection**  
  - What it does: Unlocks new flowers from streaks or purchase.  
  - When it appears: When streak goals are met or purchase is complete.  
  - If something goes wrong: Do not remove existing flowers.

- **F-007: Garden Dropdown**  
  - What it does: Opens a list of all owned flowers.  
  - When it appears: When the user taps the dropdown on the main screen.  
  - If something goes wrong: Show an empty garden message.

---

## 5. Screens

- **S-001: Main Flower Screen**  
  - What’s on it: Current flower, partner status, streak count, garden dropdown.  
  - How you get there: App opens here.

- **S-002: Flower Care Screen**  
  - What’s on it: Daily question, text answer box, photo button, send button.  
  - How you get there: Tap the flower on S-001.

- **S-003: Garden Screen**  
  - What’s on it: List or grid of all flowers owned.  
  - How you get there: Tap the dropdown on S-001.

- **S-004: Purchase / Unlock Screen**  
  - What’s on it: New flowers to unlock and how to get them.  
  - How you get there: From garden or a button on main screen.

---

## 6. Data

- **D-001**: User account (simple ID for each person).  
- **D-002**: Partner connection (who the couple is).  
- **D-003**: List of flowers owned.  
- **D-004**: Current flower in use.  
- **D-005**: Daily question for each flower.  
- **D-006**: User’s answer text.  
- **D-007**: User’s photo for the day.  
- **D-008**: Daily completion status for both users.  
- **D-009**: Streak count.

---

## 7. Extra Details

- Internet needed: Yes, to sync with partner and send photos.  
- Data storage: Saves data on the phone and online.  
- Permissions needed:  
  - Camera (to take photos).  
  - Photos (to pick photos).  
- Dark mode: Yes, should support dark mode.  
- Notifications: Optional daily reminder to care for the flower.

---

## 8. Build Steps

- **B-001**: Build S-001 with F-001 (main flower screen).  
- **B-002**: Add S-002 and F-002 for daily questions.  
- **B-003**: Add F-003 for photo sending.  
- **B-004**: Add D-006 and D-007 to save answers and photos.  
- **B-005**: Add F-004 to show partner status.  
- **B-006**: Add F-005 and D-009 for streaks.  
- **B-007**: Build S-003 and F-007 for the garden view.  
- **B-008**: Add F-006 and S-004 for unlocking new flowers.  
- **B-009**: Add reminders, dark mode, and polish the app.

---
🌱 End of Requirements Document

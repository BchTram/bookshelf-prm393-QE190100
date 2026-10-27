Practical Exam
Subject: PRM393 | Semester: FALL 2026
1. Overview
You will build BookShelf, a small mobile app where each person keeps their own private list of books they own or want to read, sorted into reading statuses and genres, with a favorite flag. It uses what you learned in the previous labs: a Flutter app written in Dart, forms with validation, app state shared between screens, and Firebase for login and for the database.
This exam describes what the app must do, not how to code it. How you structure the code, and which packages or state-management approach you use, is up to you, as long as the screen names and the visible texts in this document are exactly as written.
2. The application
2.1 Setup
A Flutter app that runs on Android (iOS is optional). It connects to your own Firebase project using only the client-side Firebase config, and it must build and run from a fresh copy of your source code without any changes other than that config.
In your Firebase project: enable the Email/Password sign-in provider (Authentication → Sign-in method), create one test account for the grader, and set up the database as described in section 2.2.
2.2 Database (Firestore)
Design the collection yourself in your Firebase project (Firestore Database) and save the Security Rules you used as firestore.rules in your project. Create one collection named books that stores everything the app saves. It must have at least the fields below. The field names must be exactly as written, because the grader reads and writes them directly through your Firebase project with the test account; you choose the data types, defaults and indexes.
| Field | What it holds |
| --- | --- |
| id | a unique id for each book (the Firestore document id) |
| userId | the person the book belongs to (the logged-in user's id) |
| title | the book's title |
| author | the book's author |
| genre | one of Fiction, Non-Fiction, Academic, Other |
| status | one of To Read, Reading, Finished |
| rating | an optional rating from 0 to 5 (empty by default) |
| favorite | true or false (false by default) |
| notes | an optional short text (empty by default) |
| createdAt | when the book was added |


The database itself must refuse bad data, not only your forms. The grader sends writes that break these rules straight to Firestore with the test account and expects an error each time:
title is required (spaces only does not count) and at most 100 characters.
author is required (spaces only does not count) and at most 60 characters.
genre must be one of the four genres above; anything else is refused.
status must be one of the three statuses above; anything else is refused.
rating, if present, must be a whole number from 0 to 5.
notes is at most 300 characters; a longer note is refused.
the same person cannot save the same title + author twice, even if the letter case differs (for example “Dune” and “dune” by the same author); two different people may save the same book.
Security rules.
Keep Firestore Security Rules turned on and write the rules yourself so that:
a person who is logged in can see and change only their own rows (read, add, change, delete) and nothing else; every book belongs to the person who saved it;
a book whose userId is another person's id is rejected when it is saved;
a visitor who is not logged in can neither read nor write anything.
Allow only the actions the app really needs, and never use an admin/service-account key in the app.
2.3 Screens and what they do
Home (public, first screen)
A header with the app name and, when logged out, a Login button and a Register button. Below it a title with the text BookShelf and a short description of the app, with at least three feature cards (for example “Track your books”, “Sort by status”, “Rate your favorites”).
When logged in, the app opens directly on the List screen instead, whose header shows the user’s e-mail and a Logout button. After Logout you are back on the Home screen.
Register and Login
Forms with your own validation messages, shown under the field they belong to. Nothing is shown before the first submit; an error disappears once its field becomes valid. Register has e-mail, password and confirm password; Login has e-mail and password. Password fields hide what is typed.
With valid input, Register creates a real Firebase Authentication account and shows the message Registration successful; Login signs in for real and goes to the List screen. If Firebase refuses (duplicate email, wrong password) its message is shown on the form, below the submit button, and nothing else happens.
| Field | When | Exact error message |
| --- | --- | --- |
| Email (both forms) | empty / not a valid e-mail | Email is required / Please enter a valid email address |
| Password (both forms) | empty / fewer than 6 characters (Register only) | Password is required / Password must be at least 6 characters |
| Confirm password (Register) | empty / different from password | Confirm password is required / Passwords do not match |


List screen (protected)
This screen is only reachable after a successful Login or Register. While the app is still checking whether someone is already logged in, nothing from this screen is shown (a loading indicator is fine; no flash of content, no wrong navigation). Pressing the phone’s Back button on the List screen must not return to the Login or Register form.
A. Add a book.
A form with: title, author, genre (a dropdown with an empty first choice “Choose genre”, then Fiction, Non-Fiction, Academic, Other), status (a dropdown with an empty first choice “Choose status”, then To Read, Reading, Finished), an optional rating and an optional note. Validation runs when the form is submitted; nothing is shown on first load; each message disappears when its field is valid.
| Field | Rule | Exact error message |
| --- | --- | --- |
| Title | empty or spaces only / longer than 100 characters | Title is required / Title must be at most 100 characters |
| Author | empty or spaces only / longer than 60 characters | Author is required / Author must be at most 60 characters |
| Genre | nothing chosen | Please choose a genre |
| Status | nothing chosen | Please choose a status |
| Rating | only if filled in: not a whole number from 0 to 5 | Rating must be a whole number from 0 to 5 |
| Notes | longer than 300 characters | Notes must be at most 300 characters |


With valid input the book is saved in Firestore for the logged-in user, appears in the list at once without reloading the screen, the form is cleared, and the message Book added is shown. If Firestore returns an error — for example the same title + author was already saved — show its message on the form and do not add anything to the list.
B. The list.
All the user’s books in alphabetical order by title (not case-sensitive; equal titles ordered by author). Each book in the list shows its title, author, genre, status, a favorite toggle (a star button that is “on” for favorites) and a way to open its Detail screen. Toggling the favorite is saved in Firestore and the item updates at once; after closing and reopening the app the list is exactly the same. When there is nothing to show, display the text No books found instead of the list.
C. Filter, search and summary.
All of these work on what is on screen and update immediately (no button to press):
A genre filter (All, or one of the four genres), a status filter (All, or one of the three statuses), a “favorites only” switch, and a search box that keeps only books whose title or author contains the typed text (not case-sensitive, spaces at both ends ignored). They all combine (every one that is set must match). A Clear button resets all four. When a book stops matching because of a change (for example it is un-favorited while “favorites only” is on) it disappears from the list at once.
The summary always describes the books currently shown: the number of books (text Books: N, where N is a plain integer), how many of them are favorites (text Favorites: N) and a breakdown with one row per status that appears, the status with the most books first (equal counts: To Read, then Reading, then Finished), each row showing the status name and how many books it has.
Detail screen (protected)
Opened by tapping a book in the list. Shows that one book’s full details (title, author, genre, status, rating, notes) and a favorite toggle. An Edit action switches the same fields into editable inputs with Save and Cancel buttons; the same validation rules and messages as the Add Book form apply, and Save updates the book in Firestore and returns to view mode. A Delete action removes the book (after a confirmation dialog with Cancel and Delete) and returns to the List screen, and the book is gone from the list immediately, also after closing and reopening the app. Going back to the List screen shows any change made here at once.
2.4 Look and feel
The app must be usable on a typical phone screen without any text or button being cut off, overlapping, or requiring sideways scrolling. Keep spacing, font sizes and colors consistent across every screen, and reuse the same components (buttons, inputs, cards) rather than styling each screen differently.
3. Screenshots for each screen
Screenshots are part of your report and are how the grader checks everything that cannot be read directly from your Firebase project. For every screen and feature listed in section 2 that you actually built, include one clearly captioned screenshot in your <StudentCode>.docx report, in the order below, with the caption naming the screen and the feature it shows. Only include a screenshot for something you really built — do not reuse or fake one; a missing, uncaptioned, or mismatched screenshot counts that feature as not done.
Take every app screenshot from a real device or emulator session signed in with your own test account, not from a design tool or mockup.
Firebase console — Authentication: the Users list showing your test account.
Firebase console — Firestore data: the books collection with at least 3 sample documents belonging to your test account.
Firebase console — Security Rules: the Rules tab showing the rules you actually have published, not just saved in an editor.
Register screen — validation: the form submitted empty, showing the error messages.
Register screen — success: right after a successful sign-up, showing Registration successful.
Login screen: the empty sign-in form.
List screen — after login: showing the user’s e-mail, the Logout button, and at least 3 books already in the list.
Add Book form — validation: the form submitted empty or with bad input, showing the error messages.
Add Book form — success: right after adding a book, showing Book added and the new book now in the list.
Filters and search: the genre filter, the status filter, the favorites-only switch, and the search box each changing what is shown — one screenshot per control, or one screenshot plus a short note, is fine.
Summary: the Books and Favorites counts and the status breakdown visible, with more than one status represented.
Detail screen — view mode: one book’s full details (title, author, genre, status, rating, notes).
Detail screen — edit mode, validation: an edit submitted with bad input, showing the error messages.
Detail screen — after Save: showing the edited values now saved.
Favorite toggle and Delete: a before/after pair showing the star toggled, and a book deleted and gone from the list.
Empty state: the List screen with the text No books found — easiest to capture with a second, fresh test account before it has any books.
Caption each screenshot with the screen/feature it shows (for example “List screen — after login”). Screenshots without a caption, or that do not match what they claim to show, are not counted.
4. Submission
Put two files in the same folder and submit that folder (both named with your student code):
<StudentCode>.docx — one real Word file (.docx or .doc, not a PDF or a renamed file). Copy this template exactly and write each URL as plain visible text with https://:
| Student Code: QE200012<br>Full Name: Nguyen Van A<br>GitHub Repository URL: https://github.com/username/repo-name<br>APK Download Link: https://github.com/username/repo-name/releases/download/v1.0/app-release.apk<br>Firebase Project ID: your-project-id<br>Test account email: grader.qe200012@example.com<br>Test account password: Test1234! |
| --- |


<StudentCode>.zip — your source code: pubspec.yaml at the top level of the zip (not inside an extra folder), pubspec.lock, the lib/ folder, the android/ folder, any assets you use, and firestore.rules. Do not include build output or cache folders (build/, .dart_tool/), the .git folder, or any admin/service-account key.
Only the client-side Firebase config.
Never put an admin/service-account key in the zip, in the Word file, or in your code.
The GitHub repository must be public and contain the same code as the zip (the zip is what is graded). The APK download link must still work after the exam — build a release APK and upload it somewhere public and durable (for example GitHub Releases, or Google Drive shared with “Anyone with the link”), not a file that only exists on your own computer.
The test account must already exist in your Firebase project and be able to log in. Log in with it once in your app and add at least a couple of books before you submit.
5. Submission Self-check before submitting
Register with a new e-mail works at once; registering the same e-mail again shows Firebase’s message on the form.
Logged out, the app opens on the Home screen; after logging in you land on the List screen, which shows your e-mail and a working Logout.
Submitting the empty Add Book form shows the title, author, genre and status messages; none are visible when the screen first loads.
Adding a book shows it at once in alphabetical position; closing and reopening the app keeps it; adding the same title + author again shows the Firestore error and adds nothing.
The favorite star toggles at once and stays after the app restarts; with “favorites only” on, un-starring a book removes it from the list.
With at least five books in at least two statuses: genre filter, status filter, favorites-only, search, count, favorite count and breakdown all change correctly together; Clear resets all four.
Opening a book’s Detail screen shows the right data; editing and saving updates both the Detail screen and the List screen; Delete removes the book, also after restarting the app.
Logging out and logging in with another account shows an empty list, not the first account’s books.
A fresh copy of the unzipped folder builds and runs with only your Firebase config added, and the release APK from your link installs and opens on a phone or emulator.
The zip has no build/, .dart_tool/, .git or admin key; the Word file follows the template; both files are named with your student code and are in the same folder.
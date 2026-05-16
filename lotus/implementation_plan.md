# Professional ERP Upgrade Plan

Based on your feedback, we will upgrade the backend to operate like a professional ERP system by fully utilizing relational databases (UUIDs instead of raw text fields) and providing a safe, student-specific ID for the Community features.

## Proposed Changes

### 1. Student IDs & Friend System
Instead of exposing the backend `auth.users` UID, we will introduce a `student_id` (e.g., an admission number or unique student tag).
- **Database**: Add a `student_id` column to the `profiles` table (unique, text).
- **Friendships**: The `friendships` table will still use internal UUIDs for relational integrity, but the Flutter UI will ask users to enter their friend's `student_id`. The app will look up the internal UUID based on the `student_id` before sending the request.

### 2. Upgrading Class Management (Relational Database Upgrade)
Currently, tables like `profiles`, `homework`, `notices`, and `assignments` use flat text columns (`class` and `section`) to map data. A professional ERP links everything to a centralized `class_rooms` table.

- **Database Migrations**:
  - Add `class_id` (UUID) to `homework`, `notices`, `assignments`, and `calendar_events`, linking to the `class_rooms` table.
  - We will transition from using the raw `class` and `section` text columns to using the `class_id` foreign key.
- **Flutter Code (`ClassManagementRepository`)**:
  - Update the repository to fetch the student's `class_id` from `profiles`.
  - Fetch the corresponding class details directly from the `class_rooms` table.
  - Update `ClassScope` model to use `class_id` (UUID) instead of `classNumber` and `section` strings.
  - Update `watchClassHomeworks` to filter by `class_id` instead of string matching.

### 3. Community Page Upgrades
- Implement the "Add Friend" UI to search using the new `student_id`.
- Show pending and accepted friend requests securely.

## User Review Required
> [!IMPORTANT]
> **Data Migration**
> Upgrading the class management to use `class_id` means that any existing dummy data in your app that relies purely on the string `class` or `section` will need to be linked to a real row in the `class_rooms` table. I will provide a script to generate a few dummy classes if needed. 
> Does this relational class management approach align with your vision for the ERP system?

## Verification Plan
- Verify that a `student_id` can be generated and used to add friends safely.
- Verify the `class_rooms` relation correctly pulls homework for a student based on their assigned `class_id`.

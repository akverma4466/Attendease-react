# AttendEase · Period-Wise College Attendance & Academic Management System
**Modern React 18 + Supabase Edition**

---

## 🌟 Overview
**AttendEase** is a comprehensive, institutional-grade college attendance management web application designed for engineering, arts, and science colleges. It manages hourly/period-wise attendance, weekly class timetables, date-specific substitutions and lecture cancellations, and computes statutory attendance percentages with automated Defaulter List & Notice generation.

---

## 🚀 Key Features & Enhancements

### 1. Dual Engine Architecture (Instant Zero-Config Demo Mode + Supabase Cloud)
- **Instant Out-Of-The-Box Demo Mode**: Works immediately in any browser with realistic pre-loaded CSE, IT, and ECE classes, subjects, students, timetable, and attendance records.
- **Supabase Cloud Ready**: Connects directly to Supabase via `@supabase/supabase-js`. Enter your Project URL & Anon Key in the in-app Settings modal or via `.env`.

### 2. Period-Wise Daily Attendance
- Pick **Date + Class** $\to$ Scheduled lecture periods are automatically derived from the **Weekly Timetable + Daily Date Overrides**.
- Shows subject, room number, and time slot.
- Fast batch actions: **Mark All Present (P)**, **Mark All Absent (A)**, **Mark All Leave (L)**.
- Live summary counters (Present count & %, Absent count & %, Leave count & %).
- Seamlessly records both student-level records and class-level session status (`attendance_sessions` = `held`).

### 3. Interactive Weekly Timetable Grid
- Interactive visual matrix of **Monday through Saturday $\times$ Periods 1 through 8**.
- Displays subject code, teacher name, and lecture hall / lab.
- Ability to add, update, and remove timetable slots.

### 4. Date-Specific Timetable Overrides & Substitutions
- Substitute a faculty member or subject for a specific date without modifying the weekly master schedule.
- Cancel an individual period for a specific date (e.g., faculty on leave or college fest).

### 5. Manage Class Sessions (Held vs Cancelled)
- Record session status without entering roll call for individual students.

### 6. Defaulter Alert & Warning Letter Generator (<75%)
- Automatic detection of students whose attendance has fallen below the university statutory **75% requirement**.
- **1-Click Official Defaulter Warning Notice Generator**: Formatted printable letter ready for submission to the Dean / HOD and student signature.

### 7. Subject-Wise Analytics & Multi-Format Export
- Dynamic attendance percentage calculation:
  $$\text{Attendance \%} = \left(\frac{\text{Periods Attended}}{\text{Periods Held}}\right) \times 100$$
- **CSV Export**: Clean spreadsheet output.
- **Multi-Column Excel Matrix (.xlsx)**: Uses SheetJS to generate a date-by-date matrix showing every student's attendance on every lecture date, total attended, total held, and percentage.

### 8. Excel Student Roster Bulk Import & Template Generator
- Download a pre-formatted `AttendEase_Student_Import_Template.xlsx`.
- Upload Excel (`.xlsx`, `.xls`) or `.csv` files.
- Live preview dialog with automatic column normalization (`roll_no`, `name`).

### 9. Role-Based Access Control (Admin vs Teacher)
- **Admin**: Full master setup, class/subject/student creation, teacher account assignment, weekly timetable builder.
- **Teacher**: Take attendance, view assigned classes, check timetable, generate reports.
- **Role Switcher**: 1-click toggle to test both views instantly.

---

## 📁 Project Structure

```
attendease-react/
├── index.html            # Standalone, zero-install React 18 browser runner
├── schema.sql            # Complete Supabase PostgreSQL schema with RLS & functions
├── package.json          # Vite + React package config
├── vite.config.js        # Vite build configuration
├── src/
│   ├── main.jsx          # React DOM entry point
│   ├── App.jsx           # Main React component
│   ├── index.css         # Tailwind CSS styling
│   ├── mockData.js       # Pre-loaded college sample database
│   └── supabaseClient.js # Supabase connection initialization
└── README.md             # Documentation
```

---

## 🏃 How to Run the Project

### Option A: Open Directly in Any Browser (Zero Installation Required!)
1. Navigate to:
   ```
   C:\Users\akver\.gemini\antigravity\scratch\attendease-react\index.html
   ```
2. Double-click `index.html` to open it in Chrome, Edge, or Firefox.
3. Everything is bundled and ready to use immediately!

### Option B: Local Python HTTP Server
```bash
cd C:\Users\akver\.gemini\antigravity\scratch\attendease-react
python -m http.server 3000
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

### Option C: Vite + React (with Node.js)
```bash
cd C:\Users\akver\.gemini\antigravity\scratch\attendease-react
npm install
npm run dev
```

---

## 🗄️ Supabase PostgreSQL Setup
To connect to your own Supabase backend:
1. Go to your [Supabase Dashboard](https://supabase.com).
2. Open the **SQL Editor**.
3. Copy the entire contents of `schema.sql` and run it.
4. Go to **Project Settings $\to$ API** and copy:
   - **Project URL**
   - **anon / public key**
5. In AttendEase, click the **⚙️ Settings** icon in the top header, paste the credentials, and click **Save Configuration**.

---

## 🔑 Default Demo Credentials
- **Admin**: `admin@college.edu` / `admin12345678`
- **Teacher**: `teacher@college.edu` / `teacher123456`
*(Or use the 1-click quick login buttons on the sign-in screen)*

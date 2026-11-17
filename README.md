# Prakash Homeo Hall (प्रकाश होमियो हॉल)
## Doctor Clinic Online Appointment Booking & Live Queue Management System

एक पूर्ण एवं आधुनिक **Doctor Clinic Appointment Booking & Live Queue Management System** जो विशेष रूप से **Prakash Homeo Hall (Dr. Om Prakash, B.H.M.S.), Chandiyana, Fatehpur, Uttar Pradesh** के लिए तैयार किया गया है।

यह सिस्टम 100% **Free & Open-Source** तकनीकों पर आधारित है। इसमें किसी भी Paid Service (Firebase, Pusher, Paid SMS/WhatsApp Gateway) की आवश्यकता नहीं है।

---

## 🏗️ System Architecture & Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend** | Flutter 3.x (Web + Android) | Multi-platform Medical UI, Clean Architecture |
| **State Management** | Provider | Reactive state with dynamic auto-sync |
| **API Client** | Dio | Interceptors, retry logic, error handling |
| **Backend** | Laravel 11/12/13 REST API | Robust MVC, Sanctum token authentication |
| **Database** | SQLite / MySQL | Row locking (`lockForUpdate`), DB transactions |
| **Live Updates** | REST API Polling (5s) | Automatic refresh without battery drain |
| **Timezone** | `Asia/Kolkata` (IST) | Full Indian Standard Timezone support |

---

## 👥 Three Complete Panels Included

### 1. Patient Panel
- **Doctor & Clinic Information**: View Dr. Om Prakash's profile, B.H.M.S. qualification, address in Chandiyana Fatehpur, and OPD timings (10:00 AM - 1:00 PM, 5:00 PM - 8:00 PM).
- **Online Booking**: Select date, pick 15-minute slot, enter patient details with double-click protection.
- **Booking Confirmation**: Generates unique booking ID (e.g. `PHH-261118-001ABC`) & sequential daily token number. Option to copy/share appointment slip.
- **Live Queue Tracking**: Real-time 5-second polling showing:
  - Current token with doctor
  - Patient's live queue position & patients ahead
  - Estimated waiting time
  - Secure mobile verification for appointment cancellation.

### 2. Doctor Dashboard
- **Secure Authentication**: Sanctum Bearer token login (`doctor@prakashhomeo.com` / `password123`).
- **Real-time Queue Management**:
  - Summary cards: Total Today, Waiting, Completed, Current, Upcoming, Cancelled.
  - Active Consultation Room Card: View current patient details and symptoms.
  - Action buttons: **Call Patient**, **Start Consultation**, **Complete Consultation**, **Skip**, **Mark No-Show**.
  - **Pause / Resume Queue**: Instantly pause OPD queue during emergency or break.
  - Concurrency rule: Only 1 patient allowed in consultation at a time. Completing consultation does not auto-start next patient.

### 3. Reception Panel
- **Appointment Search**: Search by patient name, mobile number, or booking ID.
- **Patient Check-in**: One-click check-in when patient arrives at clinic to activate queue position.
- **Walk-in Booking**: Register walk-in patients on the spot using the shared atomic slot system.
- **Reschedule & Cancel**: Move appointments to other available slots or cancel.

### 4. Clinic TV Display
- High contrast, dark medical theme (`#0B132B`) for waiting room TV screens.
- Displays current token in consultation room in massive typography, next token ready, and waiting tokens queue.
- **100% Privacy Protected**: No patient names or phone numbers shown on public display.
- Auto-refreshes every 5 seconds.

---

## 🚀 Quick Setup Instructions (Localhost)

### Prerequisites
- PHP 8.2+ with `pdo_sqlite` and `pdo_mysql` extensions
- Composer 2.x
- Flutter SDK 3.x

### 1. Start Laravel Backend Server
```bash
# Navigate to backend directory
cd backend

# Install dependencies (if not already done)
composer install

# Run database migrations and seed default data
php artisan migrate --force
php artisan db:seed --force

# Start the local API server
php artisan serve --host=127.0.0.1 --port=8000
```
Backend will be live at `http://127.0.0.1:8000/api`.

### 2. Run Flutter App (Web or Android)

#### Option A: Run in Web Browser
```bash
# In the project root directory:
flutter run -d chrome
```

#### Option B: Run on Android Device / Emulator
```bash
flutter run
```
*Tip: On physical Android devices or emulators, click the Settings icon in the top right of the app to change the Backend API URL to your computer's local Wi-Fi IP (e.g. `http://192.168.1.X:8000/api`) or emulator loopback (`http://10.0.2.2:8000/api`).*

---

## 🔐 Default Login Credentials

| Role | Email | Password |
|---|---|---|
| **Doctor** | `doctor@prakashhomeo.com` | `password123` |
| **Reception** | `reception@prakashhomeo.com` | `password123` |
| **Admin** | `admin@prakashhomeo.com` | `password123` |

*Quick login buttons are also provided on the login screen for instant testing.*

---

## 🧪 Testing Checklist & Verification

All 14 requirements have been automated and tested:

- [x] **Scenario 1:** Patient successfully books appointment (`POST /api/appointments`).
- [x] **Scenario 2:** Two patients attempting to book the same slot simultaneously result in exactly one booking succeeding via DB row locking (`lockForUpdate`).
- [x] **Scenario 3:** Past slots and past dates are rejected with 422 error.
- [x] **Scenario 4:** Booked slots are filtered out from `GET /api/slots`.
- [x] **Scenario 5:** Reception marks patient as `checked_in`.
- [x] **Scenario 6:** Doctor calls checked-in patient (`POST /api/doctor/appointments/{id}/call`).
- [x] **Scenario 7:** Doctor starts consultation (`start`) and completes (`complete`). Single active consultation enforced.
- [x] **Scenario 8:** Live queue updates token and waiting count (`GET /api/queue/live`).
- [x] **Scenario 9:** Doctor pauses queue (`pause`), blocking new calls until resumed (`resume`).
- [x] **Scenario 10:** Cancelled appointments remain in database with audit logs in `appointment_status_logs`.
- [x] **Scenario 11:** Walk-in patient booking functions with slot locking and immediate check-in.
- [x] **Scenario 12:** Unauthorized users are blocked from doctor APIs (401 / 403).
- [x] **Scenario 13:** Dio client handles network disconnects gracefully without app crash.
- [x] **Scenario 14:** Responsive design verified for Mobile, Tablet, and Web TV screens.

Run the test suite anytime:
```bash
cd backend && php artisan test --filter=ClinicSystemTest
flutter test
```

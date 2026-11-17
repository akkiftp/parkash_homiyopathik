# Prakash Homeo Hall – REST API Documentation
Doctor Clinic Online Appointment Booking & Live Queue Management System

Base URL: `http://127.0.0.1:8000/api`
Default Timezone: `Asia/Kolkata`

---

## 1. Public APIs (Patient & Clinic)

### 1.1 Clinic Information
- **Endpoint:** `GET /clinic`
- **Description:** Returns clinic details, doctor qualification, specialization, address, and active OPD schedules.
- **Response:**
```json
{
  "success": true,
  "message": "Clinic details fetched successfully.",
  "data": {
    "clinic_name": "Prakash Homeo Hall",
    "doctor_name": "Dr. Om Prakash",
    "qualification": "B.H.M.S. (Senior Homeopathic Consultant)",
    "specialization": "Classical Homeopathy & Chronic Care",
    "address": "Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601",
    "phone": "+91 94150 12345",
    "slot_duration": 15,
    "timezone": "Asia/Kolkata",
    "opd_timings": [
      {
        "id": 1,
        "weekday": "all",
        "session_name": "Morning OPD",
        "start_time": "10:00 AM",
        "end_time": "1:00 PM"
      },
      {
        "id": 2,
        "weekday": "all",
        "session_name": "Evening OPD",
        "start_time": "5:00 PM",
        "end_time": "8:00 PM"
      }
    ],
    "queue_paused": false
  }
}
```

---

### 1.2 Available Slots
- **Endpoint:** `GET /slots?date=YYYY-MM-DD`
- **Description:** Returns available 15-minute slots for the given date. Past dates and past time slots today are excluded. Booked slots are filtered out.
- **Parameters:**
  - `date` (query, required): `YYYY-MM-DD`
- **Response:**
```json
{
  "success": true,
  "message": "Available slots retrieved successfully.",
  "data": {
    "date": "2026-11-18",
    "total_available": 24,
    "slots": [
      {
        "id": 1,
        "slot_date": "2026-11-18",
        "start_time": "10:00",
        "end_time": "10:15",
        "formatted_time": "10:00 AM",
        "is_available": true
      }
    ]
  }
}
```

---

### 1.3 Book Appointment
- **Endpoint:** `POST /appointments`
- **Description:** Books an appointment with database transaction and row locking (`lockForUpdate()`) to prevent race conditions. Assigns sequential daily token number.
- **Request Body:**
```json
{
  "patient_name": "Ramesh Kumar",
  "mobile": "9876543210",
  "clinic_slot_id": 1,
  "notes": "Chronic headache"
}
```
- **Response (201 Created):**
```json
{
  "success": true,
  "message": "Appointment booked successfully.",
  "data": {
    "booking_id": "PHH-261118-001ABC",
    "patient_name": "Ramesh Kumar",
    "mobile": "9876543210",
    "appointment_date": "2026-11-18",
    "appointment_time": "10:00 AM",
    "slot_start": "10:00",
    "token_number": 1,
    "status": "booked",
    "clinic_name": "Prakash Homeo Hall",
    "doctor_name": "Dr. Om Prakash",
    "address": "Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601"
  }
}
```

---

### 1.4 Track Appointment & Live Queue
- **Endpoint:** `GET /appointments/{booking_code}`
- **Description:** Returns current appointment status, running token, calculated queue position, patients ahead, and estimated wait minutes.
- **Response:**
```json
{
  "success": true,
  "message": "Appointment details fetched successfully.",
  "data": {
    "booking_id": "PHH-261118-001ABC",
    "patient_name": "Ramesh Kumar",
    "mobile": "9876543210",
    "token_number": 1,
    "appointment_date": "2026-11-18",
    "appointment_time": "10:00 AM",
    "status": "checked_in",
    "is_today": true,
    "queue_paused": false,
    "current_running_token": null,
    "queue_position": 1,
    "patients_ahead": 0,
    "estimated_wait_minutes": 0,
    "clinic_name": "Prakash Homeo Hall",
    "doctor_name": "Dr. Om Prakash"
  }
}
```

---

### 1.5 Live Public Queue (TV Display / App Polling)
- **Endpoint:** `GET /queue/live`
- **Description:** Polled every 5 seconds. Contains NO private patient information (no names or phones).
- **Response:**
```json
{
  "success": true,
  "message": "Live queue status fetched.",
  "data": {
    "clinic_name": "Prakash Homeo Hall",
    "doctor_name": "Dr. Om Prakash",
    "specialization": "Classical Homeopathy & Chronic Care",
    "queue_paused": false,
    "current_token": 1,
    "current_patient_status": "in_consultation",
    "next_token": 2,
    "waiting_count": 2,
    "waiting_tokens": [2, 3],
    "completed_count": 1,
    "total_today": 4,
    "timestamp": "2026-11-18T10:30:00+05:30"
  }
}
```

---

### 1.6 Cancel Appointment (Verified)
- **Endpoint:** `POST /appointments/{booking_code}/cancel`
- **Description:** Requires patient mobile number matching the booking so unauthorized users cannot cancel. Releases slot.
- **Request Body:**
```json
{
  "mobile": "9876543210",
  "reason": "Personal emergency"
}
```

---

## 2. Authentication APIs

### 2.1 Login
- **Endpoint:** `POST /login`
- **Request Body:**
```json
{
  "email": "doctor@prakashhomeo.com",
  "password": "password123"
}
```
- **Response:**
```json
{
  "success": true,
  "message": "Logged in successfully.",
  "data": {
    "token": "1|SWvnLLEtg...",
    "user": {
      "id": 1,
      "name": "Dr. Om Prakash",
      "email": "doctor@prakashhomeo.com",
      "role": "doctor"
    }
  }
}
```

---

## 3. Doctor Dashboard APIs (Bearer Token, Role: Doctor)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/doctor/dashboard` | Today summary cards, current consultation, called patient, waiting list |
| `GET` | `/api/doctor/appointments` | List appointments with date/status filter |
| `POST` | `/api/doctor/appointments/{id}/call` | Calls patient (status `called`) |
| `POST` | `/api/doctor/appointments/{id}/start` | Starts consultation (status `in_consultation`). Single active consultation enforced |
| `POST` | `/api/doctor/appointments/{id}/complete` | Marks consultation `completed`. Does not auto-start next patient |
| `POST` | `/api/doctor/appointments/{id}/skip` | Skips patient (status `skipped`) |
| `POST` | `/api/doctor/appointments/{id}/no-show` | Marks patient as `no_show` |
| `POST` | `/api/doctor/queue/pause` | Pauses OPD queue (blocks new call actions) |
| `POST` | `/api/doctor/queue/resume` | Resumes OPD queue |

---

## 4. Reception Dashboard APIs (Bearer Token, Role: Reception)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/reception/appointments` | Search by name, mobile, booking code |
| `POST` | `/api/reception/walk-in` | Books walk-in patient with slot row locking and marks `checked_in` |
| `POST` | `/api/reception/appointments/{id}/check-in` | Checks in arriving patient, adds to doctor waiting list |
| `POST` | `/api/reception/appointments/{id}/reschedule` | Moves appointment to new slot with atomic lock |
| `POST` | `/api/reception/appointments/{id}/cancel` | Cancels appointment and releases slot |
| `POST` | `/api/reception/appointments/{id}/no-show` | Marks patient as `no_show` |

---

## 5. Seeded Accounts

- **Doctor:** `doctor@prakashhomeo.com` | `password123`
- **Reception:** `reception@prakashhomeo.com` | `password123`
- **Admin:** `admin@prakashhomeo.com` | `password123`

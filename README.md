# 📅 BookMe: Appointment Booking App

A full-stack appointment booking app for clinics, salons, barbers, and other service businesses: a **Flutter** app backed by a **Laravel 12 REST API**.

Customers find a business, pick a service, choose a day and a free time slot, and book in a few taps. Business owners get a daily schedule and can mark appointments as completed or no-show.

## Features

**Mobile app (Flutter)**
- Explore businesses with search (by name or service) and category filters
- Business page with services, prices, durations, and opening hours (today is highlighted)
- Booking flow with a 14-day date strip, **live free-slot loading**, and notes for the provider
- If someone takes the slot first, the app shows an error and refreshes the available times
- Upcoming and history tabs, with cancellation

**Backend (Laravel)**
- **Availability engine:** builds slots from each business's working hours, service duration, and slot step, then removes overlapping bookings and times that have already passed
- **No double booking:** the provider row is locked during booking (`lockForUpdate`) and the slot is re-validated inside the transaction
- A customer can't book two appointments that overlap
- Cancellation policy: allowed up to 2 hours before the appointment
- Owner endpoints: daily schedule and status updates (completed / no-show)
- "Starting from" price computed with `withMin`
- Feature tests for slot generation, closed days, double booking, and cancellation

## Tech stack

| Layer | Tech |
|---|---|
| Mobile | Flutter 3, Dart, Provider, http, shared_preferences, intl |
| API | PHP 8.2+, Laravel 12, Sanctum |
| Database | SQLite (dev), MySQL / PostgreSQL ready |
| Tests | PHPUnit, flutter_test |

## Getting started

### Backend
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed
php artisan serve
```
Demo accounts (password: `password`): `demo@bookme.test` (customer), `owner@bookme.test` (business owner)

Run tests: `php artisan test`

### Mobile
```bash
cd mobile
flutter create . --project-name bookme --platforms android,ios
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api
```

## API endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register`, `/api/auth/login` | – | Auth |
| GET | `/api/categories` | – | Business categories |
| GET | `/api/providers?q=&category=&city=` | – | Browse businesses |
| GET | `/api/providers/{id}` | – | Details, services, and hours |
| GET | `/api/providers/{id}/slots?service_id=&date=` | – | Free start times |
| GET | `/api/appointments?scope=upcoming\|past` | ✔ | My appointments |
| POST | `/api/appointments` | ✔ | Book (`service_id`, `starts_at: "2026-12-01 10:30"`) |
| POST | `/api/appointments/{id}/cancel` | ✔ | Cancel |
| GET | `/api/schedule?date=` | Owner | Day schedule for my businesses |
| PATCH | `/api/appointments/{id}/status` | Owner | Mark completed or no-show |

## License

MIT

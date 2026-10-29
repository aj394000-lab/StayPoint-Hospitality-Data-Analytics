-- Sprint 2: Database Setup
CREATE DATABASE staypoint_hospitality;
USE staypoint_hospitality;

-- 1. Create Hotels Table
CREATE TABLE hotels (
    hotel_id VARCHAR(20) PRIMARY KEY,
    hotel_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    star_rating INT,
    total_rooms INT,
    opened_date DATE
);

-- 2. Create Guests Table
CREATE TABLE guests (
    guest_id VARCHAR(20) PRIMARY KEY,
    guest_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    guest_type VARCHAR(20),
    preferred_room_type VARCHAR(20),
    loyalty_tier VARCHAR(20),
    account_since DATE
);

-- 3. Create Staff Table
CREATE TABLE staff (
    staff_id VARCHAR(20) PRIMARY KEY,
    staff_name VARCHAR(100) NOT NULL,
    hire_date DATE,
    rating DECIMAL(3,2),
    department VARCHAR(30),
    is_active VARCHAR(3)
);

-- 4. Create Rooms Table
CREATE TABLE rooms (
    room_id VARCHAR(20) PRIMARY KEY,
    hotel_id VARCHAR(20),
    room_type VARCHAR(20),
    floor_number INT,
    max_occupancy INT,
    price_per_night DECIMAL(10,2),
    is_active VARCHAR(3),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

-- 5. Create Bookings Table
CREATE TABLE bookings (
    booking_id VARCHAR(20) PRIMARY KEY,
    guest_id VARCHAR(20),
    hotel_id VARCHAR(20),
    booking_date DATE,
    room_type_requested VARCHAR(20),
    booking_channel VARCHAR(30),
    nights_booked INT,
    total_amount DECIMAL(12,2),
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

-- 6. Create Stays Table
CREATE TABLE stays (
    stay_id VARCHAR(20) PRIMARY KEY,
    booking_id VARCHAR(20),
    room_id VARCHAR(20),
    staff_id VARCHAR(20),
    check_in_date DATE,
    check_out_date DATE,
    status VARCHAR(20),
    nights_stayed INT,
    service_requests INT,
    stay_duration_hrs INT,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

-- Sprint 3: Basic Analysis / Data Exploration
-- 1. Total number of guests
SELECT COUNT(*) AS total_guests FROM guests;

-- 2. Total number of bookings
SELECT COUNT(*) AS total_bookings FROM bookings;

-- 3. Total number of stays
SELECT COUNT(*) AS total_stays FROM stays;

-- 4. Different room types available
SELECT DISTINCT room_type FROM rooms;

-- 5. Active staff members (Assuming the column has 'Yes' for active)
SELECT COUNT(*) AS active_staff FROM staff WHERE is_active = 'Yes';

-- 6. Different booking channels
SELECT DISTINCT booking_channel FROM bookings;

-- 7. Total booking amount across all bookings
SELECT SUM(total_amount) AS total_revenue FROM bookings;

-- 8. Average nights booked per booking
SELECT ROUND(AVG(nights_booked), 2) AS avg_nights_booked FROM bookings;

-- Sprint 4: Objective-Based Analysis:
-- 4.1 Understand Booking Demand:
-- 1. Compare the number of bookings across hotels:
SELECT h.hotel_name, 
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_amount) AS total_revenue
FROM hotels h
JOIN bookings b ON h.hotel_id = b.hotel_id
GROUP BY h.hotel_name
ORDER BY total_bookings DESC;

-- 2. Compare bookings across different booking channels:
SELECT booking_channel, 
    COUNT(booking_id) AS total_bookings,
    ROUND(AVG(nights_booked), 2) AS avg_nights,
    SUM(total_amount) AS total_revenue
FROM bookings
GROUP BY booking_channel
ORDER BY total_bookings DESC;

-- 3. Compare bookings based on room type requested:
SELECT room_type_requested, 
    COUNT(booking_id) AS total_bookings,
    SUM(total_amount) AS total_revenue
FROM bookings
GROUP BY room_type_requested
ORDER BY total_bookings DESC;

-- 4.2 Understand Guest Booking Behaviour:
-- 1. Identify Guests with Multiple Bookings & High Spend:
SELECT g.guest_name, 
    g.guest_type, 
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_amount) AS total_spent
FROM guests g
JOIN bookings b ON g.guest_id = b.guest_id
GROUP BY g.guest_id, g.guest_name, g.guest_type
HAVING total_bookings > 1
ORDER BY total_bookings DESC, total_spent DESC;

-- 2. Compare Individual vs. Corporate Guests:
SELECT g.guest_type, 
    COUNT(DISTINCT g.guest_id) AS total_unique_guests,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_amount) AS total_revenue,
    ROUND(AVG(b.nights_booked), 2) AS avg_nights_stayed
FROM guests g
JOIN bookings b ON g.guest_id = b.guest_id
GROUP BY g.guest_type;

-- 3. Guest Activity by Loyalty Tier:
SELECT g.loyalty_tier, 
    COUNT(DISTINCT g.guest_id) AS total_guests,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_amount) AS total_revenue
FROM guests g
JOIN bookings b ON g.guest_id = b.guest_id
GROUP BY g.loyalty_tier
ORDER BY total_revenue DESC;

-- 4.3 Evaluate Stay Performance:
-- 1. Stay Outcomes by Status:
SELECT status, 
    COUNT(stay_id) AS total_stays,
    ROUND(AVG(nights_stayed), 2) AS avg_nights,
    ROUND(AVG(stay_duration_hrs), 2) AS avg_duration_hrs
FROM stays
GROUP BY status
ORDER BY total_stays DESC;

-- 2. Compare Stay Outcomes Across Different Hotels:
SELECT h.hotel_name, 
    s.status, 
    COUNT(s.stay_id) AS stay_count
FROM hotels h
JOIN bookings b ON h.hotel_id = b.hotel_id
JOIN stays s ON b.booking_id = s.booking_id
GROUP BY h.hotel_name, s.status
ORDER BY h.hotel_name, stay_count DESC;

-- 3. Identify Hotels with the Highest Problem Rates:
SELECT h.hotel_name,
    COUNT(s.stay_id) AS total_stays,
    COUNT(CASE WHEN s.status IN ('Cancelled', 'No-show') THEN 1 END) AS problem_stays,
    ROUND((COUNT(CASE WHEN s.status IN ('Cancelled', 'No-show') THEN 1 END) / COUNT(s.stay_id)) * 100, 2) AS problem_rate_percentage
FROM hotels h
JOIN bookings b ON h.hotel_id = b.hotel_id
JOIN stays s ON b.booking_id = s.booking_id
GROUP BY h.hotel_name
ORDER BY problem_rate_percentage DESC;

-- 4.4 Understand Staff and Room Performance:
-- 1. Stays Handled by Staff Members:
SELECT st.staff_name, 
    st.department,
    COUNT(s.stay_id) AS stays_handled,
    ROUND(AVG(s.stay_duration_hrs), 2) AS avg_stay_duration_hrs
FROM staff st
JOIN stays s ON st.staff_id = s.staff_id
GROUP BY st.staff_id, st.staff_name, st.department
ORDER BY stays_handled DESC;

-- 2. Room Usage and Service Requests by Room Type:
SELECT r.room_type, 
    COUNT(s.stay_id) AS total_stays,
    ROUND(AVG(s.nights_stayed), 2) AS avg_nights,
    SUM(s.service_requests) AS total_service_requests
FROM rooms r
JOIN stays s ON r.room_id = s.room_id
GROUP BY r.room_type
ORDER BY total_stays DESC;

-- 3. Staff Performance Across Stay Outcomes:
SELECT st.staff_name, 
    s.status, 
    COUNT(s.stay_id) AS stay_count
FROM staff st
JOIN stays s ON st.staff_id = s.staff_id
GROUP BY st.staff_name, s.status
ORDER BY st.staff_name, stay_count DESC;

-- 4.5 Identify Booking and Stay Problems:
-- 1. Problem Rates by Booking Channel:
SELECT b.booking_channel,
    COUNT(s.stay_id) AS total_stays,
    SUM(CASE WHEN s.status IN ('Cancelled', 'No-show') THEN 1 ELSE 0 END) AS problem_stays,
    ROUND((SUM(CASE WHEN s.status IN ('Cancelled', 'No-show') THEN 1 ELSE 0 END) / COUNT(s.stay_id)) * 100, 2) AS failure_rate_percentage
FROM bookings b
JOIN stays s ON b.booking_id = s.booking_id
GROUP BY b.booking_channel
ORDER BY failure_rate_percentage DESC;

-- 2. Service Requests Driven by Room Capacity:
SELECT r.max_occupancy,
    COUNT(s.stay_id) AS total_stays,
    SUM(s.service_requests) AS total_requests,
    ROUND(AVG(s.service_requests), 2) AS avg_requests_per_stay
FROM rooms r
JOIN stays s ON r.room_id = s.room_id
GROUP BY r.max_occupancy
ORDER BY avg_requests_per_stay DESC;

-- 3. Problem Stays by Guest Type:
SELECT g.guest_type,
    COUNT(s.stay_id) AS total_stays,
    SUM(CASE WHEN s.status IN ('Cancelled', 'No-show') THEN 1 ELSE 0 END) AS problem_stays,
    ROUND((SUM(CASE WHEN s.status IN ('Cancelled', 'No-show') THEN 1 ELSE 0 END) / COUNT(s.stay_id)) * 100, 2) AS problem_rate_percentage
FROM guests g
JOIN bookings b ON g.guest_id = b.guest_id
JOIN stays s ON b.booking_id = s.booking_id
GROUP BY g.guest_type;

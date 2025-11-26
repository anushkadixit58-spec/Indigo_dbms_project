-- 1. Create the Database
CREATE DATABASE IndiGo_IAMS;
USE IndiGo_IAMS;

-- 2. AIRPORTS (Master Table)
-- We use CHAR(3) for codes like DEL, BOM because it is fixed length and faster than VARCHAR.
CREATE TABLE Airports (
    Airport_Code CHAR(3) PRIMARY KEY,
    City_Name VARCHAR(50) NOT NULL,
    Airport_Name VARCHAR(100) NOT NULL,
    Terminal_Count TINYINT DEFAULT 1 -- TINYINT saves space (0-255 range)
);

-- 3. AIRCRAFTS (Master Table)
CREATE TABLE Aircrafts (
    Aircraft_ID INT PRIMARY KEY AUTO_INCREMENT,
    Model VARCHAR(20) NOT NULL, -- e.g. 'Airbus A320'
    Registration_Number CHAR(6) UNIQUE NOT NULL, -- e.g. 'VT-IVX'
    Total_Seats SMALLINT NOT NULL, -- SMALLINT (up to 32,000) is better than INT for seat counts
    Last_Maintenance_Date DATE
);

-- 4. ROUTES (Master Table)
CREATE TABLE Routes (
    Route_ID INT PRIMARY KEY AUTO_INCREMENT,
    Origin_Airport CHAR(3),
    Dest_Airport CHAR(3),
    Distance_KM SMALLINT,
    Base_Fare DECIMAL(10,2) NOT NULL, -- DECIMAL is mandatory for money to avoid rounding errors
    FOREIGN KEY (Origin_Airport) REFERENCES Airports(Airport_Code),
    FOREIGN KEY (Dest_Airport) REFERENCES Airports(Airport_Code)
);

-- 5. FLIGHTS (Transaction Table)
CREATE TABLE Flights (
    Flight_ID INT PRIMARY KEY AUTO_INCREMENT,
    Flight_Number VARCHAR(10) NOT NULL, -- e.g. '6E-204'
    Aircraft_ID INT,
    Route_ID INT,
    Departure_Time DATETIME NOT NULL,
    Arrival_Time DATETIME NOT NULL,
    -- ENUM saves massive storage space by storing strings as integers internally
    Status ENUM('Scheduled', 'Delayed', 'Cancelled', 'Landed') DEFAULT 'Scheduled',
    FOREIGN KEY (Aircraft_ID) REFERENCES Aircrafts(Aircraft_ID),
    FOREIGN KEY (Route_ID) REFERENCES Routes(Route_ID)
);

-- 6. LOYALTY PROGRAM (6E Rewards)
CREATE TABLE Loyalty_Program (
    Member_ID INT PRIMARY KEY AUTO_INCREMENT,
    Points_Balance INT DEFAULT 0,
    Tier ENUM('Silver', 'Gold', 'Platinum') DEFAULT 'Silver',
    Join_Date DATE
);

-- 7. PASSENGERS
CREATE TABLE Passengers (
    Passenger_ID INT PRIMARY KEY AUTO_INCREMENT,
    First_Name VARCHAR(50) NOT NULL,
    Last_Name VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    Loyalty_Member_ID INT NULL, -- Nullable because not everyone is a member
    FOREIGN KEY (Loyalty_Member_ID) REFERENCES Loyalty_Program(Member_ID)
);

-- 8. BOOKINGS
CREATE TABLE Bookings (
    Booking_ID INT PRIMARY KEY AUTO_INCREMENT,
    Passenger_ID INT,
    Flight_ID INT,
    Booking_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
    Seat_Number VARCHAR(4), -- e.g. '12F'
    Total_Amount DECIMAL(10,2),
    Payment_Status TINYINT DEFAULT 0, -- 0=Pending, 1=Paid
    FOREIGN KEY (Passenger_ID) REFERENCES Passengers(Passenger_ID),
    FOREIGN KEY (Flight_ID) REFERENCES Flights(Flight_ID)
);

-- 9. BAGGAGE (Ancillary Revenue)
CREATE TABLE Baggage (
    Baggage_ID INT PRIMARY KEY AUTO_INCREMENT,
    Booking_ID INT,
    Weight_KG DECIMAL(4,2), -- Allows weights like 15.50 kg
    Type ENUM('Cabin', 'Check-in', 'Excess'),
    Fee_Amount DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (Booking_ID) REFERENCES Bookings(Booking_ID)
);

-- 10. CREW (Staff)
CREATE TABLE Crew (
    Crew_ID INT PRIMARY KEY AUTO_INCREMENT,
    Full_Name VARCHAR(100),
    Role ENUM('Pilot', 'Co-Pilot', 'Cabin Crew'),
    License_Number VARCHAR(20) UNIQUE
);

-- 11. FLIGHT_CREW_ASSIGNMENT (Many-to-Many Link Table)
CREATE TABLE Flight_Crew_Assignment (
    Assignment_ID INT PRIMARY KEY AUTO_INCREMENT,
    Flight_ID INT,
    Crew_ID INT,
    FOREIGN KEY (Flight_ID) REFERENCES Flights(Flight_ID),
    FOREIGN KEY (Crew_ID) REFERENCES Crew(Crew_ID)
);



-- Insert Airports
INSERT INTO Airports VALUES 
('DEL', 'New Delhi', 'Indira Gandhi International', 3),
('BOM', 'Mumbai', 'Chhatrapati Shivaji Maharaj', 2),
('BLR', 'Bangalore', 'Kempegowda International', 2);

-- Insert Aircraft
INSERT INTO Aircrafts (Model, Registration_Number, Total_Seats, Last_Maintenance_Date) VALUES 
('Airbus A320neo', 'VT-IVX', 186, '2023-10-01');

-- Insert Route
INSERT INTO Routes (Origin_Airport, Dest_Airport, Distance_KM, Base_Fare) VALUES 
('DEL', 'BOM', 1148, 4500.00);

-- Insert Flight
INSERT INTO Flights (Flight_Number, Aircraft_ID, Route_ID, Departure_Time, Arrival_Time, Status) VALUES 
('6E-505', 1, 1, '2023-12-25 10:00:00', '2023-12-25 12:15:00', 'Scheduled');

-- 1. Add a Passenger (Note: Loyalty_Member_ID is NULL for now to keep it simple)
INSERT INTO Passengers (First_Name, Last_Name, Email, Phone, Loyalty_Member_ID) 
VALUES ('Rahul', 'Verma', 'rahul.v@example.com', '9876543210', NULL);

-- 2. Add a Booking for that Passenger
-- We are linking Passenger_ID 1 to Flight_ID 1
INSERT INTO Bookings (Passenger_ID, Flight_ID, Booking_Date, Seat_Number, Total_Amount, Payment_Status) 
VALUES (1, 1, '2023-12-01 14:30:00', '12F', 4500.00, 1);


SELECT 
    p.First_Name, 
    p.Last_Name, 
    f.Flight_Number, 
    f.Departure_Time, 
    a1.City_Name AS 'From', 
    a2.City_Name AS 'To', 
    b.Seat_Number 
FROM Bookings b
JOIN Passengers p ON b.Passenger_ID = p.Passenger_ID
JOIN Flights f ON b.Flight_ID = f.Flight_ID
JOIN Routes r ON f.Route_ID = r.Route_ID
JOIN Airports a1 ON r.Origin_Airport = a1.Airport_Code
JOIN Airports a2 ON r.Dest_Airport = a2.Airport_Code;

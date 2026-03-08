-- Create customer table
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    date_of_birth   DATE,
    gender          CHAR(1)      CHECK (gender IN ('M', 'F', 'O')),
    address_line1   VARCHAR(100),
    address_line2   VARCHAR(100),
    city            VARCHAR(50),
    state           VARCHAR(50),
    postal_code     VARCHAR(20),
    country         VARCHAR(50)  DEFAULT 'US',
    loyalty_tier    VARCHAR(20)  CHECK (loyalty_tier IN ('Bronze', 'Silver', 'Gold', 'Platinum')) DEFAULT 'Bronze',
    total_spent     NUMERIC(10,2) DEFAULT 0.00,
    is_active       BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMPTZ  DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  DEFAULT NOW()
);

-- Insert sample data
INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, gender, address_line1, city, state, postal_code, country, loyalty_tier, total_spent, is_active) VALUES
('James',    'Anderson',  'james.anderson@email.com',  '+1-212-555-0101', '1985-03-14', 'M', '123 Broadway Ave',     'New York',    'NY', '10001', 'US', 'Platinum', 15420.50, TRUE),
('Sarah',    'Mitchell',  'sarah.mitchell@email.com',  '+1-310-555-0192', '1990-07-22', 'F', '456 Sunset Blvd',      'Los Angeles', 'CA', '90028', 'US', 'Gold',     8230.75,  TRUE),
('Michael',  'Torres',    'michael.torres@email.com',  '+1-312-555-0148', '1978-11-05', 'M', '789 Lake Shore Dr',    'Chicago',     'IL', '60601', 'US', 'Gold',     6875.00,  TRUE),
('Emily',    'Chen',      'emily.chen@email.com',      '+1-713-555-0173', '1995-01-30', 'F', '321 Houston St',       'Houston',     'TX', '77001', 'US', 'Silver',   3210.25,  TRUE),
('David',    'Nguyen',    'david.nguyen@email.com',    '+1-602-555-0165', '1988-09-17', 'M', '654 Desert Palm Rd',   'Phoenix',     'AZ', '85001', 'US', 'Silver',   2890.40,  TRUE),
('Jessica',  'Williams',  'jessica.williams@email.com','+1-215-555-0134', '1992-04-08', 'F', '987 Liberty Bell Ln',  'Philadelphia','PA', '19101', 'US', 'Bronze',   950.00,   TRUE),
('Robert',   'Johnson',   'robert.johnson@email.com',  '+1-210-555-0187', '1975-12-25', 'M', '147 Alamo Plaza',      'San Antonio', 'TX', '78201', 'US', 'Platinum', 22100.90, TRUE),
('Ashley',   'Brown',     'ashley.brown@email.com',    '+1-619-555-0112', '1998-06-11', 'F', '258 Pacific Cove',     'San Diego',   'CA', '92101', 'US', 'Bronze',   410.60,   TRUE),
('Daniel',   'Martinez',  'daniel.martinez@email.com', '+1-214-555-0156', '1983-08-29', 'M', '369 Lone Star Ave',    'Dallas',      'TX', '75201', 'US', 'Gold',     7650.15,  TRUE),
('Amanda',   'Taylor',    'amanda.taylor@email.com',   '+1-408-555-0123', '1991-02-14', 'F', '741 Silicon Valley Rd','San Jose',    'CA', '95101', 'US', 'Silver',   4120.80,  TRUE),
('Chris',    'Lee',       'chris.lee@email.com',       '+1-512-555-0198', '1987-10-03', 'M', '852 Congress Ave',     'Austin',      'TX', '78701', 'US', 'Gold',     5500.00,  TRUE),
('Megan',    'Harris',    'megan.harris@email.com',    '+1-904-555-0141', '1994-05-19', 'F', '963 Sunshine Blvd',    'Jacksonville','FL', '32099', 'US', 'Bronze',   750.30,   FALSE),
('Kevin',    'Clark',     'kevin.clark@email.com',     '+1-614-555-0177', '1980-07-07', 'M', '111 Buckeye Lane',     'Columbus',    'OH', '43085', 'US', 'Silver',   3800.45,  TRUE),
('Lauren',   'Lewis',     'lauren.lewis@email.com',    '+1-317-555-0163', '1996-03-27', 'F', '222 Monument Circle',  'Indianapolis','IN', '46201', 'US', 'Bronze',   220.00,   TRUE),
('Brian',    'Walker',    'brian.walker@email.com',    '+1-512-555-0109', '1973-09-12', 'M', '333 Barton Springs Rd','Austin',      'TX', '78704', 'US', 'Platinum', 18750.60, TRUE);

-- Useful queries to verify
SELECT * FROM customers ORDER BY customer_id;

SELECT loyalty_tier, COUNT(*) AS count, ROUND(AVG(total_spent), 2) AS avg_spent
FROM customers
GROUP BY loyalty_tier
ORDER BY avg_spent DESC;

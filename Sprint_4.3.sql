CREATE DATABASE IF NOT EXISTS Ecommerce;
USE Ecommerce;

-- Tabla: companies
CREATE TABLE companies (
    company_id VARCHAR(50) PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    country VARCHAR(50),
    website VARCHAR(100)
);

SHOW variables like 'secure_file_priv';

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv"
INTO TABLE companies
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(company_id, company_name, phone, email, country, website);

SELECT * FROM companies;

SELECT *
FROM companies;

CREATE TABLE products (
    id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price VARCHAR(20),
    colour VARCHAR(10),# formato hexadecimal, como #7c7c7c
    weight DECIMAL(10,2),
    warehouse_id VARCHAR(10)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv"
INTO TABLE products
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id);

SELECT * FROM products;

UPDATE products
SET price = REPLACE(price, '$', '');
ALTER TABLE products
MODIFY COLUMN price DECIMAL(10,2);
SELECT * FROM products;

-- Tabla: american_users
CREATE TABLE american_users (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(50),
    surname VARCHAR(50),
    phone VARCHAR(50),
    email VARCHAR(100),
    birth_date VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    address VARCHAR(100)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/american_users.csv"
INTO TABLE american_users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id,name, surname, phone, email, birth_date,country,city,postal_code,address);

SELECT *
FROM american_users;

-- Tabla: european_users
CREATE TABLE european_users (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(50),
    surname VARCHAR(50),
    phone VARCHAR(50),
    email VARCHAR(100),
    birth_date VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    address VARCHAR(100)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/european_users.csv"
INTO TABLE european_users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id,name, surname, phone, email, birth_date,country,city,postal_code,address);

SELECT *
FROM european_users;

CREATE TABLE users (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(50),
    surname VARCHAR(50),
    phone VARCHAR(50),
    email VARCHAR(100),
    birth_date VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    address VARCHAR(100),
    region ENUM('american', 'european')  -- para saber de qué tabla vino
);


-- Insertar usuarios americanos
INSERT INTO users
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, 'american'
FROM american_users;

-- Insertar usuarios europeos
INSERT INTO users
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, 'european'
FROM european_users;

SELECT * FROM users LIMIT 10;
SELECT COUNT(*) FROM users;

#eliminar las tablas european y american users.
DROP TABLE american_users;
DROP TABLE european_users;

#cambiar el tipo de fecha
UPDATE users
SET birth_date = STR_TO_DATE(birth_date, '%b %d, %Y');
-- Cambiar tipo de columna
ALTER TABLE users MODIFY COLUMN birth_date DATE;
SELECT birth_date FROM users;

describe users;
SELECT id, birth_date FROM users LIMIT 10;

-- Tabla: credit_cards
CREATE TABLE credit_cards (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(100),
    iban VARCHAR(34),
    pan VARCHAR(20),
    pin VARCHAR(10),
    cvv VARCHAR(4),
    track1 TEXT,
    track2 TEXT,
    expiring_date VARCHAR(50)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv"
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, user_id,iban,pan,pin,cvv, track1,track2,expiring_date);


UPDATE credit_cards
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%Y');
ALTER TABLE credit_cards MODIFY COLUMN expiring_date DATE;
SELECT * FROM credit_cards;

ALTER TABLE credit_cards
ADD FOREIGN KEY (user_id) REFERENCES users(id);

CREATE TABLE transactions (
    id VARCHAR(100) PRIMARY KEY,
    card_id VARCHAR(50),
    business_id VARCHAR(50),
    timestamp DATETIME,
    amount DECIMAL(10,2),
    declined BOOLEAN,
    product_ids VARCHAR(100),
    user_id INT,
    lat DECIMAL(12,8),
    longitude DECIMAL(12,8)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude);

SELECT * FROM transactions;
ALTER TABLE transactions MODIFY COLUMN user_id VARCHAR(100);

-- transactions.user_id → users.id
ALTER TABLE transactions
ADD FOREIGN KEY (user_id) REFERENCES users(id);

-- transactions.card_id → credit_cards.id
ALTER TABLE transactions
ADD FOREIGN KEY (card_id) REFERENCES credit_cards(id);

-- transactions.business_id → companies.company_id
ALTER TABLE transactions
ADD FOREIGN KEY (business_id) REFERENCES companies(company_id);


/*Ejercicio 1
Realiza una subconsulta que muestre a todos los usuarios con más de 80 
transacciones utilizando al menos 2 tablas.*/

SELECT u.id,u.name,u.surname,COUNT(T.id) as total_transaction
FROM users u
JOIN transactions T ON u.id=T.user_id
WHERE declined=0
GROUP BY u.id,u.name 
HAVING COUNT(t.id) > 80; #hacerlo con subconsulta

SELECT u.id,u.name,u.surname
FROM users u
WHERE u.id IN  (SELECT t.user_id
			FROM transactions t
            WHERE declined=0
            GROUP BY t.user_id
            HAVING COUNT(t.id) > 80);
            
/*Ejercicio 2
Muestra la media de amount por IBAN de las tarjetas de crédito 
en la compañía Donec Ltd., utiliza por lo menos 2 tablas.*/

SELECT cc.iban,AVG(t.amount) AS Avg_amount,C.company_name
FROM credit_cards cc
JOIN transactions t ON cc.id=t.card_id
JOIN companies C ON C.company_id=t.business_id
WHERE company_name='Donec Ltd' AND declined=0
GROUP BY cc.iban,C.company_name
ORDER BY Avg_amount desc;


/*Nivel 2
Crea una nueva tabla que refleje el estado de las tarjetas de crédito 
basado en si las últimas tres transacciones fueron declinadas y genera la siguiente consulta:*/

/*Ejercicio 1
¿Cuántas tarjetas están activas?*/

#CREAMOS UNA NUEVA TABLA STATUS_CREDIT_CARD 
CREATE TABLE status_credit_card (
    card_id VARCHAR(50) PRIMARY KEY,
    status_card VARCHAR(50) NOT NULL,
    FOREIGN KEY (card_id) REFERENCES credit_cards(id)
    );
    
#CARGAMOS LA NUEVA TABLA CON LAS CONDICIONES CORRESPONDIENTES
INSERT INTO status_credit_card (card_id, status_card)
SELECT card_id,
       CASE 
           WHEN SUM(CASE WHEN declined THEN 1 ELSE 0 END) = 3 THEN 'Inactiva'
           ELSE 'Activa'
       END AS card_status
FROM (
    SELECT card_id, declined,
           ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS latest_transactions
    FROM transactions
) AS t
WHERE latest_transactions <= 3
GROUP BY card_id;

#CONTAMOS CUANTAS TARJETAS ESTAN ACTIVAS
SELECT COUNT(*) AS tarjetas_activas
FROM status_credit_card
WHERE status_card = 'Activa';


/*Crea una tabla con la que podamos unir los datos del nuevo archivo products.csv 
con la base de datos creada, teniendo en cuenta que desde transaction tienes product_ids. Genera la siguiente consulta:

Ejercicio 1
#Necesitamos conocer el número de veces que se ha vendido cada producto.*/

CREATE TABLE transaction_products (
    transaction_id VARCHAR(100),
    product_id INT,
    PRIMARY KEY (transaction_id, product_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO transaction_products (transaction_id, product_id) 
SELECT transactions.id AS transactions_id, products.id AS products_id
FROM transactions
JOIN products
ON FIND_IN_SET(products.id, REPLACE(transactions.product_ids, ' ', '')) > 0;


SELECT product_id, COUNT(*) AS num_ventas
FROM transaction_products
JOIN transactions ON transaction_id = transactions.id
WHERE declined = 0
GROUP BY product_id
ORDER BY num_ventas DESC;


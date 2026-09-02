CREATE DATABASE IF NOT EXISTS fraude_cartao;
USE fraude_cartao;

--  Tabela de transações financeiras
CREATE TABLE IF NOT EXISTS transacoes (
    trans_date_trans_time DATETIME, 
    cc_num VARCHAR(20),
    merchant VARCHAR(100), 
    category VARCHAR(50), 
    amt DECIMAL(10,2), 
    first VARCHAR(50), 
    last VARCHAR(50), 
    gender CHAR(1), 
    street VARCHAR(150), 
    city VARCHAR(50), 
    state VARCHAR(2), 
    zip VARCHAR(10), 
    lat DECIMAL(15,6), 
    lng DECIMAL(15,6), 
    city_pop INT, 
    job VARCHAR(100), 
    dob DATE, 
    trans_num VARCHAR(50), 
    unix_time INT, 
    merch_lat DECIMAL(15,6), 
    merch_long DECIMAL(15,6), 
    is_fraud TINYINT(1)
);

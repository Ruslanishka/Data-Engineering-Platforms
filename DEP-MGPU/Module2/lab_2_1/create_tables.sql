-- Staging layer (stg):
DROP TABLE IF EXISTS stg.orders;
CREATE TABLE stg.orders(
Row_ID INTEGER NOT NULL PRIMARY KEY
 ,Order_ID VARCHAR(14) NOT NULL
 ,Order_Date DATE NOT NULL
 ,Ship_Date DATE NOT NULL
 ,Ship_Mode VARCHAR(14) NOT NULL
 ,Customer_ID VARCHAR(8) NOT NULL
 ,Customer_Name VARCHAR(22) NOT NULL
 ,Segment VARCHAR(11) NOT NULL
 ,Country VARCHAR(13) NOT NULL
 ,City VARCHAR(17) NOT NULL
 ,State VARCHAR(20) NOT NULL
 ,Postal_Code VARCHAR(50) --varchar because can start from 0
 ,Region VARCHAR(7) NOT NULL
 ,Product_ID VARCHAR(15) NOT NULL
 ,Category VARCHAR(15) NOT NULL
 ,SubCategory VARCHAR(11) NOT NULL
 ,Product_Name VARCHAR(127) NOT NULL
 ,Sales NUMERIC(9,4) NOT NULL
 ,Quantity INTEGER NOT NULL
 ,Discount NUMERIC(4,2) NOT NULL
 ,Profit NUMERIC(21,16) NOT NULL
);

/*
Типы данных:
INTEGER - числовой тип (целые числа)
VARCHAR(...) - строковый тип данных переменного размера (в скобках указыввется максимальное число символов)
NUMERIC(21,16)  - числовое значение с фиксированной точностью и масштабом (в нашем случае можно хранить до 21 цифры 16 цифр будут находиться после запятой, а оставшиеся 5 цифр — до запятой), используется, когда требуется высокая точность при хранении данных 
DATE - тип данных для хранения дат
Для Postal_Code был выбран тип VARCHAR, так как значение может начинаться с 0
*/

-- Raw Data layer:

-- Создание таблицы Orders
DROP TABLE IF EXISTS orders;
CREATE TABLE orders(
Row_ID INTEGER NOT NULL PRIMARY KEY
 ,Order_ID VARCHAR(14) NOT NULL
 ,Order_Date DATE NOT NULL
 ,Ship_Date DATE NOT NULL
 ,Ship_Mode VARCHAR(14) NOT NULL
 ,Customer_ID VARCHAR(8) NOT NULL
 ,Customer_Name VARCHAR(22) NOT NULL
 ,Segment VARCHAR(11) NOT NULL
 ,Country VARCHAR(13) NOT NULL
 ,City VARCHAR(17) NOT NULL
 ,State VARCHAR(20) NOT NULL
 ,Postal_Code INTEGER
 ,Region VARCHAR(7) NOT NULL
 ,Product_ID VARCHAR(15) NOT NULL
 ,Category VARCHAR(15) NOT NULL
 ,SubCategory VARCHAR(11) NOT NULL
 ,Product_Name VARCHAR(127) NOT NULL
 ,Sales NUMERIC(9,4) NOT NULL
 ,Quantity INTEGER NOT NULL
 ,Discount NUMERIC(4,2) NOT NULL
 ,Profit NUMERIC(21,16) NOT NULL
);

-- Создание таблицы People
DROP TABLE IF EXISTS people;
CREATE TABLE people(
Person VARCHAR(17) NOT NULL PRIMARY KEY
 ,Region VARCHAR(7) NOT NULL
);

-- Создание таблицы Returns
DROP TABLE IF EXISTS returns;
CREATE TABLE returns(
 Person VARCHAR(17) NOT NULL,
 Region VARCHAR(20) NOT NULL
);

/*
Типы данных:
INTEGER - числовой тип (целые числа)
VARCHAR(...) - строковый тип данных переменного размера (в скобках указыввется максимальное число символов)
NUMERIC(21,16)  - числовое значение с фиксированной точностью и масштабом (в нашем случае можно хранить до 21 цифры 16 цифр будут находиться после запятой, а оставшиеся 5 цифр — до запятой), используется, когда требуется высокая точность при хранении данных 
DATE - тип данных для хранения дат
*/

-- Data Warehouse layer (dw):

-- ********** SHIPPING DIMENSION **********
-- Удаление таблицы shipping_dim, если она существует
drop table if exists dw.shipping_dim;

-- Создание таблицы shipping_dim для хранения способов доставки
CREATE TABLE dw.shipping_dim
(
 ship_id       serial NOT NULL,         
 shipping_mode varchar(14) NOT NULL,    
 CONSTRAINT PK_shipping_dim PRIMARY KEY ( ship_id )
);

-- Очистка таблицы перед загрузкой данных
truncate table dw.shipping_dim;

-- Заполнение таблицы уникальными способами доставки из stg.orders
insert into dw.shipping_dim 
select 100+row_number() over(), ship_mode from (select distinct ship_mode from stg.orders ) a;

-- Проверка содержимого таблицы shipping_dim
select * from dw.shipping_dim sd;

-- ********** CUSTOMER DIMENSION **********
-- Удаление таблицы customer_dim, если она существует
drop table if exists dw.customer_dim;

-- Создание таблицы customer_dim для хранения информации о клиентах
CREATE TABLE dw.customer_dim
(
 cust_id serial NOT NULL,               
 customer_id   varchar(8) NOT NULL,     
 customer_name varchar(22) NOT NULL,    
 CONSTRAINT PK_customer_dim PRIMARY KEY ( cust_id )
);

-- Очистка таблицы перед загрузкой данных
truncate table dw.customer_dim;

-- Заполнение таблицы уникальными клиентами из stg.orders
insert into dw.customer_dim 
select 100+row_number() over(), customer_id, customer_name from (select distinct customer_id, customer_name from stg.orders ) a;

-- Проверка содержимого таблицы customer_dim
select * from dw.customer_dim cd;

-- ********** GEOGRAPHY DIMENSION **********
-- Удаление таблицы geo_dim, если она существует
drop table if exists dw.geo_dim;

-- Создание таблицы geo_dim для хранения географической информации
CREATE TABLE dw.geo_dim
(
 geo_id      serial NOT NULL,           
 country     varchar(13) NOT NULL,      
 city        varchar(17) NOT NULL,      
 state       varchar(20) NOT NULL,    
 postal_code varchar(20) NULL,          
 CONSTRAINT PK_geo_dim PRIMARY KEY ( geo_id )
);

-- Очистка таблицы перед загрузкой данных
truncate table dw.geo_dim;

-- Заполнение таблицы уникальными географическими данными из stg.orders
insert into dw.geo_dim 
select 100+row_number() over(), country, city, state, postal_code from (select distinct country, city, state, postal_code from stg.orders ) a;

-- Проверка наличия пропущенных данных в geo_dim
select distinct country, city, state, postal_code from dw.geo_dim
where country is null or city is null or postal_code is null;

-- Обновление пропущенного почтового индекса для города Burlington
update dw.geo_dim
set postal_code = '05401'
where city = 'Burlington' and postal_code is null;

-- Также обновляем исходную таблицу stg.orders
update stg.orders
set postal_code = '05401'
where city = 'Burlington' and postal_code is null;

-- Проверка обновленных данных для Burlington
select * from dw.geo_dim where city = 'Burlington';

-- ********** PRODUCT DIMENSION **********
-- Удаление таблицы product_dim, если она существует
drop table if exists dw.product_dim;

-- Создание таблицы product_dim для хранения информации о продуктах
CREATE TABLE dw.product_dim
(
 prod_id   serial NOT NULL,             -
 product_id   varchar(50) NOT NULL,     
 product_name varchar(127) NOT NULL,    
 category     varchar(15) NOT NULL,     
 sub_category varchar(11) NOT NULL,     
 segment      varchar(11) NOT NULL,     
 CONSTRAINT PK_product_dim PRIMARY KEY ( prod_id )
);

-- Очистка таблицы перед загрузкой данных
truncate table dw.product_dim;

-- Заполнение таблицы уникальными продуктами из stg.orders
insert into dw.product_dim 
select 100+row_number() over () as prod_id ,product_id, product_name, category, subcategory, segment from (select distinct product_id, product_name, category, subcategory, segment from stg.orders ) a;

-- Проверка содержимого таблицы product_dim
select * from dw.product_dim cd;

-- ********** CALENDAR DIMENSION **********
-- Удаление таблицы calendar_dim, если она существует
drop table if exists dw.calendar_dim;

-- Создание таблицы calendar_dim для хранения календарных данных
CREATE TABLE dw.calendar_dim
(
 dateid serial NOT NULL,               
 year int NOT NULL,                     
 quarter int NOT NULL,                  
 month int NOT NULL,                    
 week int NOT NULL,                     
 date date NOT NULL,                    
 week_day varchar(20) NOT NULL,         
 leap varchar(20) NOT NULL,             
 CONSTRAINT PK_calendar_dim PRIMARY KEY ( dateid )
);

-- Очистка таблицы перед загрузкой данных
truncate table dw.calendar_dim;

-- Заполнение таблицы календарными данными с 2000 по 2030 год
insert into dw.calendar_dim 
select 
 to_char(date,'yyyymmdd')::int as date_id,  
 extract('year' from date)::int as year,
 extract('quarter' from date)::int as quarter,
 extract('month' from date)::int as month,
 extract('week' from date)::int as week,
 date::date,
 to_char(date, 'dy') as week_day,
 extract('day' from (date + interval '2 month - 1 day')) = 29 as leap
from generate_series(date '2000-01-01', date '2030-01-01', interval '1 day') as t(date);

-- Проверка содержимого таблицы calendar_dim
select * from dw.calendar_dim;

-- ********** SALES FACT TABLE **********
-- Удаление таблицы sales_fact, если она существует
drop table if exists dw.sales_fact;

-- Создание таблицы sales_fact для хранения фактических данных о продажах
CREATE TABLE dw.sales_fact
(
 sales_id      serial NOT NULL,         
 cust_id integer NOT NULL,             
 order_date_id integer NOT NULL,        
 ship_date_id integer NOT NULL,         
 prod_id  integer NOT NULL,             
 ship_id     integer NOT NULL,          
 geo_id      integer NOT NULL,          
 order_id    varchar(25) NOT NULL,     
 sales       numeric(9,4) NOT NULL,     
 profit      numeric(21,16) NOT NULL,   
 quantity    int4 NOT NULL,             
 discount    numeric(4,2) NOT NULL,     
 CONSTRAINT PK_sales_fact PRIMARY KEY ( sales_id )
);

-- Заполнение таблицы sales_fact данными из stg.orders и связанных измерений
insert into dw.sales_fact 
select
 100+row_number() over() as sales_id,
 cust_id,
 to_char(order_date,'yyyymmdd')::int as order_date_id,
 to_char(ship_date,'yyyymmdd')::int as ship_date_id,
 p.prod_id,
 s.ship_id,
 geo_id,
 o.order_id,
 sales,
 profit,
 quantity,
 discount
from stg.orders o 
inner join dw.shipping_dim s on o.ship_mode = s.shipping_mode
inner join dw.geo_dim g on o.postal_code = g.postal_code and g.country=o.country and g.city = o.city and o.state = g.state
inner join dw.product_dim p on o.product_name = p.product_name and o.segment=p.segment and o.subcategory=p.sub_category and o.category=p.category and o.product_id=p.product_id
inner join dw.customer_dim cd on cd.customer_id=o.customer_id and cd.customer_name=o.customer_name;

-- Проверка количества записей в sales_fact и корректности связей
select count(*) from dw.sales_fact sf
inner join dw.shipping_dim s on sf.ship_id=s.ship_id
inner join dw.geo_dim g on sf.geo_id=g.geo_id
inner join dw.product_dim p on sf.prod_id=p.prod_id
inner join dw.customer_dim cd on sf.cust_id=cd.cust_id;


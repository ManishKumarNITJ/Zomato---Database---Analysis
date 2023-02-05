drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Insight 1 -  What is the total amount each customer spent on Zomato

select userid , sum(price) as "Total amount each customer spent on Zomato" from 
sales  left join product
on sales.product_id = product.product_id
group by userid;


--  Insight 2 - How many days each customer visited Zomato

select userid , count(distinct created_date) as "Total days each customer visited Zomato" from sales
group by userid;


-- Insight 3 - what was the first product purchased by each customer
select userid, created_date , product_name as "First product purchased" from sales 
left join product on sales.product_id = product.product_id
where created_date in (select min(created_date) from sales group by userid)
order by userid;


-- Insight 4 - What is the most purchased item and how many times it was purchased by each customer

select top 1 product_id as "most purchased item" from sales group by product_id order by count(product_id) desc;
select userid,count(product_id) as "Times Purchased" from sales where product_id in
(select top 1 product_id from sales group by product_id order by count(product_id) desc)
group by userid;


-- Insight 5 - Which item is favorite for each customer 
select userid,product_id,cnt from  
 (select *,Rank() over (partition by userid order by cnt desc) as rnk from 
(select userid,product_id,count(product_id) cnt from sales group by userid,product_id)a) b
where rnk = 1;

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;




 -- Insight 6 - Which item was first purchased by the customer after they became a gold member ?
 
 select * from
 (select p.*,rank() over (partition by userid order by created_date) as rnk from
 (select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s
 inner join goldusers_signup g
 on s.userid = g.userid and created_date >= gold_signup_date)p)m
 where rnk = 1;


 -- Insight 7 - Which item  was purchased just before the customer become a gold member ?

 select * from
 (select p.*,rank() over (partition by userid order by created_date desc) as rnk from
 (select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s
 inner join goldusers_signup g
 on s.userid = g.userid and created_date <= gold_signup_date)p)m
 where rnk = 1;


 -- Insight 8 - What is the total orders and amount spent for each member and it's maximum also before they became a gold member?
 
 
select s.userid,count(s.product_id) as "Total Orders",sum(price) as "Amount Spent"from 
sales s left join goldusers_signup g
                  on s.userid = g.userid and created_date < gold_signup_date
        left join product p
		          on s.product_id = p.product_id
where gold_signup_date is not null
group by s.userid;


/*Insight 9 - If buying each product generates point for eg 5rs=2 Zomato points
 and each product has different purchasing points for eg - For P1 5rs = 1 zomato points,
 For P2 10rs = 5 zomato points, For P3 5rs = 1 zomato points*/

/*Calculate points calculated by each user and for which product, 
most points have been given till now*/


 select userid,sum(Zomato_points) "Total ZP",sum(Zomato_points)*2.5 as"Total Rupees Earned" from sales s left join
 (select *,
 (case when product_id = '1' then 0.2*price
      when product_id = '2' then 0.5*price 
	  when product_id = '3' then 0.2*price end) as Zomato_Points from product) m
on s.product_id = m.product_id
group by userid;



select * from 

(select*,rank() over (order by Total_ZP desc) rnk from
(select s.product_id,sum(Zomato_points) as Total_ZP  from sales s left join
(select *,
(case when product_id = '1' then 0.2*price
      when product_id = '2' then 0.5*price 
	  when product_id = '3' then 0.2*price end) as Zomato_Points from product) m
on s.product_id = m.product_id
group by s.product_id) m) j 
where rnk = 1;



/*Insight 10 - In the first year after a customeer joins the gold
program (including their joining date) irrespective of what the customer has 
purchased they earn 5 Zomato Points for every 10rs spents

Who earn more 1 or 3 and what was their points earning in the first year*/
select * from
(select *, rank() over (order by ZP_Earn_in_1st_year desc) as rnk from
(select m.userid,sum(p.price)*0.5 as ZP_Earn_in_1st_year from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s inner join goldusers_signup g
on s.userid = g.userid and  created_date between gold_signup_date and DATEADD(YEAR,1,gold_signup_date)) m
inner join
product p
on m.product_id = p.product_id
group by userid) k) t
where rnk = 1;


--Insight 11 - Rank all the transactions of the customer means which transaction was did first means according to the date



select *, Rank() over (partition by userid order by created_date desc) as rnk from sales

--Insight 12 - Rank all the transaction for each gold member and for non gold member just put NA 



select n.*,case when rnk = 0 then 'NA' else rnk end as rnkk from
(select m.*, cast((case when gold_signup_date is null then 0 else rank() over (partition by userid order by created_date desc) end) as varchar ) as rnk
from
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s
 left join goldusers_signup g
 on s.userid = g.userid and created_date >= gold_signup_date) m ) n





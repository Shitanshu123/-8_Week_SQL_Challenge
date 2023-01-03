


CREATE SCHEMA dannys_diner;
SET search_path  dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
     select * from sales
     select * from menu
     select * from members


  /*1.What is the total amount each customer spent 
     at the restaurant?*/

    select customer_id,sum(price) as total_amount
    from sales s
    join menu m
    on s.product_id=m.product_id
    group by customer_id


  /*2.How many days has each customer visited the restaurant?*/
    select customer_id,count(distinct order_date) as total_no_of_visits
    from sales
    group by customer_id

   /*3.What was the first item from the menu purchased by each customer?*/
   with cte1 as
   (select customer_id,product_id  from
   (select customer_id,product_id,
   rank() 
   over(partition by customer_id order by  customer_id,order_date ) as rn
   from sales)x
   where rn=1)
   select distinct customer_id,product_name as first_order_item
   from cte1  t1
   join menu m
   on t1.product_id=m.product_id

   /*4.What is the most purchased item on the menu and how many
    times was it purchased by all customers?*/
	 with t1 as
	 (select product_name,count(1) as no_of_times_purchased
	 from sales s
	 join menu m 
	 on s.product_id=m.product_id
	 group by product_name)
	 select product_name,no_of_times_purchased as most_purchased_item
	 from t1 where no_of_times_purchased=
	(select max(no_of_times_purchased) from t1)

	/*5.Which item was the most popular for each customer?*/
	 with t1 as
	 (select customer_id,product_id,cnt,
	 rank() over (partition by customer_id order by cnt desc) as rn
	 from
	 (select customer_id,product_id,count(*) as cnt 
	 from sales group by customer_id,product_id)x)
	 select customer_id,t1.product_id,product_name
	 from t1 
	 join menu m
	 on t1.product_id=m.product_id
	 where rn=1

	 /*6.Which item was purchased first by the customer after they became a member?*/
	 with cte1 as
	 (select s.customer_id,order_date,product_name,join_date,
	 min(order_date) over(partition by s.customer_id order by order_date) as f_o_d
	 from sales s
	 join members  mb
	 on s.customer_id=mb.customer_id
	 and s.order_date>=mb.join_date
	 join menu m 
	 on s.product_id=m.product_id)
	 select customer_id,product_name,order_date,join_date
	 from cte1
	 where order_date=f_o_d

	 /*7.Which item was purchased just before the customer became a member?*/
	 with cte1 as
	 (select s.customer_id,order_date,product_name,join_date,
	 max(cast(order_date as date))
	 over(partition by s.customer_id ) as order_date_just_before_membership
	 from sales s
	 join members  mb
	 on s.customer_id=mb.customer_id
	 and s.order_date<mb.join_date
	 join menu m 
	 on s.product_id=m.product_id)
	 select customer_id,
	 product_name as Item,order_date,join_date
	 join_date from cte1
	 where order_date=order_date_just_before_membership

	/* 8.What is the total items and amount spent for each member 
	     before they became a member?*/
	 select s.customer_id,count(1) as total_items,sum(price) as total_amt
	 from sales s
	 join members  mb
	 on s.customer_id=mb.customer_id
	 and s.order_date<mb.join_date
	 join menu m 
	 on s.product_id=m.product_id
	 group by s.customer_id

	 /*9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
	     how many points would each customer have?*/
		 with t1 as
		 (select s.customer_id,m.product_name,count(1) as total_items,sum(price) as total_amt
	     from sales s
	     join menu m 
	     on s.product_id=m.product_id
	     group by s.customer_id,m.product_name
		 )
		 select customer_id,
		 sum(case 
		 when product_name='sushi' then total_amt*2*10 
		 else total_amt*10 end)
		 as 'total_points'
		 from t1
		 group by customer_id
		 order by customer_id

	   /*10.In the first week after a customer joins the program
	     (including their join date)
	     they earn 2x points on all items, not just sushi - 
	     how many points do customer A and B have at the end of January?*/
		 with cte1 as
		 (select s.customer_id,price,order_date,join_date,
		 case 
		 when order_date  between join_date and dateadd(day,6,join_date) then price*2*10
		 when order_date not between join_date and dateadd(day,6,join_date) and product_name='sushi' then price*2*10
		 else price*10
		 end as total_points
		 from  sales s
		 join menu m
		 on s.product_id=m.product_id
		 join members mb
		 on s.customer_id=mb.customer_id
		 where month(order_date)=1)
		 select customer_id,sum(total_points) as total_points
		 from cte1 
		 group by customer_id

		 /*Bonus Questions*/

		 /*The following questions are related creating basic data tables that Danny 
		 and his team can use to quickly derive insights without needing to join
		 the underlying tables using SQL.
         Recreate the following table output using the available data:*/

		select s.customer_id,order_date,product_name,price,join_date,
		case
		when join_date is null or order_date<join_date then 'N'
		when  order_date>=join_date then 'Y'
		end as member
		from sales s
		left join menu m
		on s.product_id=m.product_id
		left join members mb
		on s.customer_id=mb.customer_id

		  /* Danny also requires further information about the 
		     ranking of customer products, but he purposely does
		     not need the ranking for non-member purchases so he 
		     expects null ranking values for
		     the records when customers are not yet part of the loyalty program*/
        with t1 as
	    (select s.customer_id,order_date,product_name,price,join_date,
		case
		when join_date is null or order_date<join_date then 'N'
		when  order_date>=join_date then 'Y'
		end as member
		from sales s
		left join menu m
		on s.product_id=m.product_id
		left join members mb
		on s.customer_id=mb.customer_id)
		select *,
		case when member='N' then NULL 
		else rank() over(partition by customer_id,member order by order_date)
		end as ranking
		from t1
		order by customer_id


		

	  



	 
	 
	 
	 
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
 





 


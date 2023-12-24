-- Identifying repeat visitors

/* pull data on how many of our website
visitors come back for another session ? 2014 to date is good.*/

-- step 1 identify the relevent new sessions
-- step 2 User the  user_id values form step1 to find any repeat sessions those users had
-- step 3 Analyze the data at the user level (how many sessions did each user have?)
-- step 4 Aggregate the user-level analysis to generate your behavioral analysis
create temporary table sessions_w_repeats
select 
     new_sessions.user_id,
     new_sessions.website_session_id as new_session_id,
     website_sessions.website_session_id as repeat_session_id
from
(
select user_id,
       website_session_id
from website_sessions
where created_at < '2014-11-01' -- the date of the assignment
      and created_at >= '2014-01-01' -- prescribed date range in assignment
      and is_repeat_session =0 
      ) as new_sessions
left join website_sessions
     on website_sessions.user_id=new_sessions.user_id
     and website_sessions.is_repeat_session = 1 -- was a repeat session 
     and website_sessions.website_session_id > new_sessions.website_session_id -- session was later then new session
     and website_sessions.created_at < '2014-11-01' -- date when request came in
     and website_sessions.created_at >= '2014-01-01' -- prescribe date range 
     ;

select 
     repeat_sessions,
     count(distinct user_id)as users
from (select
          user_id,
          count(distinct new_session_id) as new_sessions,
          count(distinct repeat_session_id) as repeat_sessions
	from sessions_w_repeats
    group by 1
    order by 3 desc
    ) as user_level
    group by 1;



-- The minimum, maximum and average time between the first and second session for customers who came back.

-- step 1 Identify the relevent new sessions 
-- step 2 user the user_id values form step 1 to find any repeat sessions those users had 
-- step 3 Find the created_at  times for first and second sessions
-- step 4 Find the difference between first and second sessions at a user level
-- step 5 Aggregate the user level data to find the average, min , max

 create temporary table sessions_w_repeats_for_time_diff
select 
      new_sessions.user_id,
      new_sessions.website_session_id as new_session_id,
      new_sessions.created_at as new_session_created_at,
      website_sessions.website_session_id as repeat_session_id,
      website_sessions.created_at as repeat_session_created_at
from 
  ( select
       user_id,
       website_session_id,
       created_at
from website_sessions
where created_at < '2014-11-03' -- date when request came in 
and created_at >= '2014-01-01' -- prescribe date range 
and is_repeat_session= 0) as new_sessions
left join website_sessions
     on website_sessions.user_id= new_sessions.user_id
     and website_sessions.is_repeat_session = 1 -- was a repeat session
     and website_sessions.website_session_id > new_sessions.website_session_id
     and website_sessions.created_at < '2014-11-03'
     and website_sessions.created_at >= '2014-1-01'
     ;

create temporary table user_first_to_second
select
   user_id,
   datediff(second_session_created_at,new_session_created_at) as days_first_to_second_session
from(
select 
     user_id,
     new_session_id,
     new_session_created_at,
     min(repeat_session_id) as second_session_id,
     min(repeat_session_created_at) as second_session_created_at
from sessions_w_repeats_for_time_diff
where repeat_session_id is not null
group by 1,2,3) as first_second;


select 
     avg(days_first_to_second_session) as avg_days_first_to_second,
     min(days_first_to_second_session) as min_days_first_to_second,
     max(days_first_to_second_session)as max_days_first_to_second
from user_first_to_second;




-- channel for the repeat sessions

select 
     utm_source,
     utm_campaign,
     http_referer,
     count(case when is_repeat_session = 0 then website_session_id else null end ) as new_sessions,
     count( case when is_repeat_session =1 then website_session_id else null end ) as repeate_sessions
     from website_sessions
     where created_at < '2014-11-05'
      and created_at >= '2014-01-01'
      group by 1,2,3
      order by 5 desc;

select 
       case 
       when utm_source is null and http_referer in('https://www.gsearch.com','https://www.bsearch.com')then 'organic_search'
       when utm_campaign='nonbrand' then 'paid_nonbrand'
       when utm_campaign ='brand' then 'paid_brand'
       when utm_source is null and http_referer is null then 'direct_type_in'
       when utm_source = 'socialbook' then 'paid_social'
       end as channel_group,
       
 count(case when is_repeat_session = 0 then website_session_id else null end ) as new_sessions,
 count( case when is_repeat_session =1 then website_session_id else null end ) as repeate_sessions      
from website_sessions
     where created_at < '2014-11-05'
      and created_at >= '2014-01-01'
group by 1
order by 3 desc;

-- comparison of conversion rate and revenue per session for repeat sessions vs new sessions.

select 
   is_repeat_session,
   count(distinct website_sessions.website_session_id) as sessions,
   count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as cov_rt,
   sum(price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
   left join orders
        on website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at < '2014-11-08'
     and website_sessions.created_at >= '2014-01-01'
     group by 1;






























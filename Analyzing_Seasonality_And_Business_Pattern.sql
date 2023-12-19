-- analyzing seasonality and business patterns
/* Request from management , 2012 was great year as we continue to grow we shoule take a look at 2012 monthly and weekly
  volume pattern  to find out any seasonal trends so that we can plan for 2013, date limit <2013-01-01*/

-- session and order by year and month
select year(website_sessions.created_at)as yr,
       month(website_sessions.created_at) as mo,
        -- min(date(website_sessions.created_at))as week_start_date,
       count(distinct website_sessions.website_session_id) as sessions,
       count(distinct orders.order_id) as orders
       from website_sessions
       left join orders
       on website_sessions.website_session_id=orders.website_session_id
       where website_sessions.created_at <'2013-01-01'
       group by 1,2;
       
-- session and order by week

    
select -- year(website_sessions.created_at)as yr,
       -- month(website_sessions.created_at) as mo,
		min(date(website_sessions.created_at))as week_start_date,
       count(distinct website_sessions.website_session_id) as sessions,
       count(distinct orders.order_id) as orders
       from website_sessions
       left join orders
       on website_sessions.website_session_id=orders.website_session_id
       where website_sessions.created_at <'2013-01-01'
       group by yearweek(website_sessions.created_at),
       month(website_sessions.created_at);



/* management is concidering to a add a live chat support to the website to improve our customer experience. so analyze 
the average website session volume, by hour of the day and by day week, so that they can staff appropriately.alter
date limit between '2012-09-15  and 2012-11-15 */

select hr,
       -- round(avg(website_sessions),1) as avg_sessions,
       round(avg(case when wkday=0 then website_sessions else null end),1) as mon,
       round(avg(case when wkday=1 then website_sessions else null end),1) as tues,
       round(avg(case when wkday=2 then website_sessions else null end),1) as weds,
	   round(avg(case when wkday=3 then website_sessions else null end),1) as thurs,
	   round(avg(case when wkday=4 then website_sessions else null end),1) as fri,
	   round(avg(case when wkday=5 then website_sessions else null end),1) as sat,
	   round(avg(case when wkday=6 then website_sessions else null end),1) as sun
from(
select 
      date(created_at) as created_date,
      weekday(created_at)as wkday,
      hour(created_at) as hr,
      count(distinct website_session_id) as website_sessions
      from website_sessions
      where created_at between '2012-09-15' and '2012-11-15'
      group by 1,2,3) as daily_hourly_sessions
      group by 1
      order by 1;
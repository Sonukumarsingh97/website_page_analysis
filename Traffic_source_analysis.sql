/* This is our first business concept where we will explore 
all the diffrent traffic sources and there conversion rate */

/* Traffic source */

/* find out where the bulk of website_sessions are comming from,
 breakdown by utm_source, utm_campaing and domain referring domain. 
 date limit 2012-04-12 */

use mavenfuzzyfactory;

select  utm_source,
     utm_campaign,
     http_referer,
 count(distinct website_session_id) as sessions
from website_sessions
 where created_at <'2012-04-12'
 group by 1,2,3
 order by sessions desc;

 /*   conversion rate */
 
 /* From last quiry we get to know that utm_source=gsearch 
 and utm_campaign= nonbrand creating all the traffic.
 In this step will calculate the conversion rate for that utm_source and utm_campaign.
 date limit 2012-04-14 */
 
 select count(distinct website_sessions.website_session_id) as sessions,
        count(distinct orders.order_id) as orders,
        count(distinct orders.order_id)/
        count(distinct website_sessions.website_session_id) as conver_rate
        from website_sessions
        left join orders
        on website_sessions.website_session_id=orders.website_session_id
        where website_sessions.created_at <'2012-04-14' 
		and utm_source='gsearch'
        and utm_campaign='nonbrand';

/* trande analysis to see the impact after bid down*/
/* Based on conversion rate analysis manager decided to bid down for the gsearch nonbrand 
Now will have to find out the impact of that, In this step will looke at the trend after bid down by week
date limit 2012-05-10 */

select
     -- year(created_at) as yr,
     -- week(created_at) as wk,
     min(date(created_at)) as week_start_day,
     count(distinct website_session_id) as sessions
     from website_sessions
     where created_at < '2012-05-10'
     and utm_source = 'gsearch'
     and utm_campaign = 'nonbrand'
     group by year(created_at),
              week(created_at) ;

/* device type conversion_rate*/
/* gsearch nonbrand is fairly sensitive to bid changes and its impotant source of traffic as well. 
so manager decided to find some other way now he is looking the conversion rate device wise to bid optimize. 
in this step will find cvr_rate device wise, date limit 2012-05-11 */

select device_type,
      count(distinct website_sessions.website_session_id) as sessions,
      count(distinct orders.order_id) as orders,
      count(distinct orders.order_id)/
      count(distinct website_sessions.website_session_id) as conv_rate
 from website_sessions
 left join orders
 on website_sessions.website_session_id=orders.website_session_id
 where website_sessions.created_at < '2012-05-11'
 and utm_source='gsearch'
 and utm_campaign='nonbrand'
 group by device_type;             














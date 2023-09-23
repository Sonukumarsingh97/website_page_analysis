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













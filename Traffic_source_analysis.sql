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
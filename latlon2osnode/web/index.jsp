<%-- 
    Document   : index
    Created on : 16-giu-2017, 10.07.04
    Author     : disit
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>latlon2osnode</title>
    </head>
<body><pre>
Distributed Systems and Internet Technologies Lab
University of Florence
http://www.disit.org/
-------------------------------------------------

/************************************************
**** latlon2osnode ******************************
************************************************/

The service is accessible through an HTTP GET 
request to the following URL:

<% 
String url = request.getRequestURL().toString();
String baseURL = url.substring(0, url.length() 
        - request.getRequestURI().length()) 
        + request.getContextPath() + "/";
out.print(baseURL);
%>Latlon2Osm

The service accepts the following parameters:

lat: decimal representation of the latitude of
     the point of your interest

lon: decimal representation of the longitude of
     the point of your interest

type: you can omit this, the default is "node". 
      If you specify "region" you will get the 
      OSM ID of the relation representing the 
      region inside which the point is located.
      Similarly, if you specify "county" or 
      "municipality". If you specify "way" you 
      will get the OSM ID of the nearest road
      element, represented as a way element.
      If you specify "node" or omit specifying 
      this parameter, you will get the OSM ID of
      the nearest node among the junction nodes
      of the above way, represented as a node
      element.

restrictions: you can omit this, the default 
              value is 0. If set to 1, the paths
              and nodes that cannot be reached by
              a pedestrian are excluded.

cfg: you can omit this, the default configuration
     will be used. Otherwise, you can specify one
     of the available configurations, and it will
     be employed. A configuration defines where
     the tool searches (host, db, user, password).

exclude_nodes: a comma separated list of OSM Node
    IDs that must be ignored. If one of those is 
    eliged for being returned, an alternative 
    is automatically searched by the service.

exclude_ways: a comma separated list of OSM Way
    IDS that must be ignored. If one of those is 
    eliged for being returned, an alternative 
    is automatically searched by the service. If 
    a node is eliged for being returned that 
    belongs to an excluded way, an alternative 
    is automatically searched by the service.

The service accesses a Postgresql relational 
database structured as a simple schema populated 
via osmosis, with PostGIS extension. Feel free 
to contact us for further details about the 
service data source, or any other information. 
</pre></body>
</html>

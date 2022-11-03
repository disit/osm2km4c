/** 
 * Licensed under GNU Affero General Public License v3.0
 */
package org.disit.latlon2osnode;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.util.ArrayList;

/**
 * @author Mirco Soderi @ DISIT DINFO UNIFI (mirco.soderi at unifi dot it)
 */
public class SearchEngine {
    
    private final String pPostgresHostname;
    private final String pPostgresPort;
    private final String pPostgresDatabase;
    private final String pPostgresUsername;
    private final String pPostgresPassword;
    
    public SearchEngine(String pPostgresHostname, String pPostgresPort,
            String pPostgresDatabase, String pPostgresUsername, 
            String pPostgresPassword) {
        this.pPostgresHostname = pPostgresHostname;
        this.pPostgresPort = pPostgresPort;
        this.pPostgresDatabase = pPostgresDatabase;
        this.pPostgresUsername = pPostgresUsername;
        this.pPostgresPassword = pPostgresPassword;
    }
    
    public Node validate(Node pt) throws Exception {
        
        Node newPt = pt;
        
        try {
            
            getMunicipality(pt);
            
        } catch(Exception e) {
            
            String query = "select " +
                "	ST_Y(ST_ClosestPoint(b.boundary, ST_GeomFromText(ST_AsText(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+")),4326))) lat, " +
                "        ST_X(ST_ClosestPoint(b.boundary, ST_GeomFromText(ST_AsText(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+")),4326))) lon " +
                "from extra_all_boundaries b " +
                "join relation_tags rt on b.relation_id = rt.relation_id and rt.k = 'admin_level' and rt.v = '8' " +
                "order by ST_Distance( " +
                "	ST_ClosestPoint(b.boundary, ST_GeomFromText(ST_AsText(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+")),4326)), " +
                "	ST_GeomFromText(ST_AsText(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+")),4326) " +
                ") " +
                "limit 1;";
            
            String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + ":" + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
            Class.forName("org.postgresql.Driver");
            try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 
                pgresConn.createStatement().execute("set statement_timeout to 60000");
                try (
                    java.sql.Statement st = pgresConn.createStatement();
                    ResultSet rs = st.executeQuery(query); 
                ) {
                    if(rs.next()) {
                        newPt = new Node(rs.getDouble(1), rs.getDouble(2));

                    }
                }
            }
            
        }
        
        return newPt;
        
    }
    
    public Region getRegion(Node pt) throws Exception {
        
        String query = "select b.relation_id " +
            "from extra_all_boundaries b " +
            "join relation_tags rt on b.relation_id = rt.relation_id and rt.k = 'admin_level' and rt.v = '4' " +
            "where ST_Covers(boundary, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+"))))";
        
        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + ":" + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 

            pgresConn.createStatement().execute("set statement_timeout to 60000");

            try (
                java.sql.Statement st = pgresConn.createStatement();
                ResultSet rs = st.executeQuery(query); 
            ) {
                if(rs.next()) {
                    Region region = new Region();
                    region.setOsmId(rs.getInt(1));
                    return region;
                }
                else
                    throw new Exception("Region not found");
            } catch(Exception e) {
                throw new Exception("ERROR: REGION"); 
            }
            
        } catch(Exception e) {
            throw new Exception("ERROR: REGION");
        }
    }
    
    public County getCounty(Node pt) throws Exception {
        
        String query = "select b.relation_id " +
            "from extra_all_boundaries b " +
            "join relation_tags rt on b.relation_id = rt.relation_id and rt.k = 'admin_level' and rt.v = '6' " +
            "where ST_Covers(boundary, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+"))))";
        
        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + ":" + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 

            pgresConn.createStatement().execute("set statement_timeout to 60000");
            
            try (
                java.sql.Statement st = pgresConn.createStatement();
                ResultSet rs = st.executeQuery(query);   
            ) {
                if(rs.next()) {
                    County county = new County();
                    county.setOsmId(rs.getInt(1));
                    return county;
                }
                else
                    throw new Exception("County not found");
            } catch(Exception e) {
                throw new Exception("ERROR: COUNTY");
            }
              
        } catch(Exception e) {
            throw new Exception("ERROR: COUNTY");
        }
    }
    
    public Municipality getMunicipality(Node pt) throws Exception {
        
        String query = "select b.relation_id " +
            "from extra_all_boundaries b " +
            "join relation_tags rt on b.relation_id = rt.relation_id and rt.k = 'admin_level' and rt.v = '8' " +
            "where ST_Covers(boundary, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+"))))";
        
        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + ":" + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 

            pgresConn.createStatement().execute("set statement_timeout to 60000");
            
            try (
                java.sql.Statement st = pgresConn.createStatement();
                ResultSet rs = st.executeQuery(query);   
            ) {       
                if(rs.next()) {
                    Municipality municipality = new Municipality();
                    municipality.setOsmId(rs.getInt(1));
                    return municipality;
                }
                else
                    throw new Exception("Municipality not found");
            } catch(Exception e) {
                throw new Exception("ERROR: MUNICIPALITY");
            }
            
        } catch(Exception e) {
            throw new Exception("ERROR: MUNICIPALITY");
        }
    }
    
    /*
    public boolean isInside(Node pt, Boundary boundary) throws Exception {
        
        String query = 
            " select * from ( " +
            "    select relation_id, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) geom from ( " +
            "        select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring " + 
            "        from relation_members join ways on relation_members.relation_id = "+boundary.getOsmId()+" and ways.id = relation_members.member_id and relation_members.member_type='W' " +
            "        order by relation_members.relation_id, relation_members.sequence_id " +
            "     ) reg group by relation_id " +
            " ) prov where ST_Covers(prov.geom, ST_SetSRID(ST_MakePoint("+pt.getLon()+", "+pt.getLat()+"),4326))" ;
        
        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + ":" + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 

            pgresConn.createStatement().execute("set statement_timeout to 60000");
            
            try (
                java.sql.Statement st = pgresConn.createStatement();
                ResultSet rs = st.executeQuery(query);  
            ) {
                return rs.next();
            } catch(Exception e) {
                throw new Exception("ERROR: IS_IN_COUNTY");
            }

        } catch(Exception e) {
            throw new Exception("ERROR: IS_IN_COUNTY");
        }
        
    }
    
    public Municipality[] getMunicipalities(County county) throws Exception {
        
        String query = "select municipality_centroid_geom.relation_id " +
            " from ( " +
            " select municip.relation_id, municip.geom from ( " +
            " select relation_id, ST_GeogFromText(ST_AsText(ST_Centroid(ST_Polygonize(linestring)))) geom, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) border from ( select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' " +
            " join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary' " +
            " join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative' " +
            " join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '8' " +
            " order by relation_members.relation_id, relation_members.sequence_id " +
            "  ) municip " +
            " group by relation_id " +
            " ) municip " +
            ") municipality_centroid_geom, ( " +
            " select * from ( " +
            "    select relation_id, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) geom from ( " +
            "        select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring " + 
            "        from relation_members join ways on relation_members.relation_id = "+county.getOsmId()+" and ways.id = relation_members.member_id and relation_members.member_type='W' " +
            "        order by relation_members.relation_id, relation_members.sequence_id " +
            "     ) reg group by relation_id " +
            " ) prov " +
            ") province_border_geom " +
            "where ST_Covers(province_border_geom.geom,municipality_centroid_geom.geom)";
        
        String jdbc = "jdbc:postgresql://" +
            pPostgresHostname + ":" + pPostgresPort + "/" +
            pPostgresDatabase + "?" +
            "user=" + pPostgresUsername + "&" +
            "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 

            pgresConn.createStatement().execute("set statement_timeout to 60000");
            
            try (
                java.sql.Statement st = pgresConn.createStatement();
                ResultSet rs = st.executeQuery(query);   
            ) { 
                ArrayList<Municipality> municipalitiesVect = new ArrayList<>();
                while(rs.next()) {
                    Municipality municip = new Municipality();
                    municip.setOsmId(rs.getInt(1));
                    municipalitiesVect.add(municip);
                }
                if(!municipalitiesVect.isEmpty()) 
                    return municipalitiesVect.toArray(new Municipality[municipalitiesVect.size()]);
                else
                    throw new Exception("ERROR: MUNICIPALITIES");
            } catch(Exception e) {
                throw new Exception("ERROR: MUNICIPALITIES");
            }
            
        } catch(Exception e) {
            throw new Exception("ERROR: MUNICIPALITIES");
        }
        
    }
    
    */
    
    public Way getWay(Municipality m, Node pt, int restrictions, ArrayList<String> exclude) throws Exception {
        
        /* VERY OLD
        String query = "select ways.id from ways "
             + "join way_nodes on ways.id = way_nodes.way_id "
             + "join nodes on way_nodes.node_id = nodes.id "
             + "join extra_all_boundaries on relation_id = "+m.getOsmId()
             + "     and ST_Covers(extra_all_boundaries.bbox,nodes.geom) " 
             + "join way_tags highway on ways.id = highway.way_id and highway.k = 'highway' " 
             + "order by ST_Distance(ways.linestring, "
             + "ST_SetSRID(ST_MakePoint("+pt.getLon()+","+pt.getLat()+"),4326))" 
             + " limit 1 ";
        */
        
        /* OLD
        String query = "select ways.id " +
            "from ways " +
            "join way_tags highway on ways.id = highway.way_id and highway.k = 'highway' " +
            "join way_nodes on ways.id = way_nodes.way_id " +
            "join nodes on way_nodes.node_id = nodes.id " +
            "join extra_all_boundaries on ST_Covers(extra_all_boundaries.boundary, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+","+pt.getLat()+")))) " +
            "where extra_all_boundaries.relation_id = "+m.getOsmId()+" and ST_Covers(extra_all_boundaries.boundary,nodes.geom) " +
            "order by ST_Distance(ways.linestring, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+","+pt.getLat()+")))) " +
            "limit 1";
        
        if(Restrictions.isActive(Restrictions.MUST_BE_REACHABLE_BY_FOOT, restrictions)) {
            query = "select ways.id " +
                "from ways " +
                "join way_tags highway on ways.id = highway.way_id and highway.k = 'highway' " +
                "join way_nodes on ways.id = way_nodes.way_id " +
                "join nodes on way_nodes.node_id = nodes.id " +
                "join extra_all_boundaries on ST_Covers(extra_all_boundaries.boundary, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+","+pt.getLat()+")))) " +
                "left join way_tags foot on ways.id = foot.way_id and foot.k = 'foot' " +
                "left join way_tags access on ways.id = access.way_id and access.k = 'access' " +
                "where extra_all_boundaries.relation_id = "+m.getOsmId()+" and ST_Covers(extra_all_boundaries.boundary,nodes.geom) " +
                "and ( ( highway.v <> 'motorway' and highway.v <> 'motorway_link' and highway.v <> 'bridleway' and highway.v <> 'cycleway' " +
                "and (not coalesce(access.v,'--') like '%private%') and coalesce(access.v, '--') <> 'no' " +
                "and coalesce(foot.v,'--') <> 'private' and coalesce(foot.v, '--') <> 'no' ) or coalesce(foot.v, 'no') <> 'no' ) " +
                "order by ST_Distance(ways.linestring, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+","+pt.getLat()+")))) " +
                "limit 1";
        }
        */
        
        String query = "select ways.id " +
            "from ways " +
            "join way_tags highway on ways.id = highway.way_id and highway.k = 'highway' " +
            "join extra_all_boundaries on ST_Intersects(extra_all_boundaries.boundary, ways.linestring) " +
            "where extra_all_boundaries.relation_id = "+m.getOsmId()+
            (exclude.size() > 0 ? " and not ways.id in (" + String.join(",", exclude) + ") " : "") + 
            " order by ST_Distance(ways.linestring, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+","+pt.getLat()+")))) " +
            "limit 1";
        
        if(Restrictions.isActive(Restrictions.MUST_BE_REACHABLE_BY_FOOT, restrictions)) {
            query = "select ways.id " +
                "from ways " +
                "join way_tags highway on ways.id = highway.way_id and highway.k = 'highway' " +
                "join extra_all_boundaries on ST_Intersects(extra_all_boundaries.boundary, ways.linestring) " +
                "left join way_tags foot on ways.id = foot.way_id and foot.k = 'foot' " +
                "left join way_tags access on ways.id = access.way_id and access.k = 'access' " +
                "where extra_all_boundaries.relation_id = "+m.getOsmId()+
                " and ( ( highway.v <> 'motorway' and highway.v <> 'motorway_link' and highway.v <> 'bridleway' and highway.v <> 'cycleway' " +
                "and (not coalesce(access.v,'--') like '%private%') and coalesce(access.v, '--') <> 'no' " +
                "and coalesce(foot.v,'--') <> 'private' and coalesce(foot.v, '--') <> 'no' ) or coalesce(foot.v, 'no') <> 'no' ) " +
                (exclude.size() > 0 ? " and not ways.id in (" + String.join(",", exclude) + ") " : "") + 
                "order by ST_Distance(ways.linestring, ST_GeogFromText(ST_AsText(ST_MakePoint("+pt.getLon()+","+pt.getLat()+")))) " +
                "limit 1";
        }
        
        
        String jdbc = "jdbc:postgresql://" +
            pPostgresHostname + ":" + pPostgresPort + "/" +
            pPostgresDatabase + "?" +
            "user=" + pPostgresUsername + "&" +
            "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 

            pgresConn.createStatement().execute("set statement_timeout to 60000");
            
            try (
                java.sql.Statement st = pgresConn.createStatement();
                ResultSet rs = st.executeQuery(query);   
            ) { 
                if(rs.next()) {
                    return new Way(rs.getInt(1));
                }
                else
                    throw new Exception("Way not found");
            } catch(Exception e) {
                throw new Exception("ERROR: WAY");
            }
           
        } catch(Exception e) {
            throw new Exception("ERROR: WAY");
        }
        
    }

    public Node getNode(Municipality municip, Way way, Node latlon, ArrayList<String> exclude) throws Exception {
        
        /*
        String query = "select nodes.id " +
            " from nodes " +
            " join way_nodes on way_nodes.node_id = nodes.id, " +
            " (  " +
            "	select * from " +
            "	(     " +
            "		select relation_id, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) geom from " +
            "		(         " +
            "			select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring from relation_members join ways on 			relation_members.relation_id = "+municip.getOsmId()+" and ways.id = relation_members.member_id and relation_members.member_type='W' order by 			relation_members.relation_id, relation_members.sequence_id      " +
            "		) reg group by relation_id  " +
            "	) municip " +
            ") municipality_border_geom " +
            "where way_nodes.way_id = " + way.getOsmId() +
            " and ST_Covers(municipality_border_geom.geom,nodes.geom) " +
            "order by ST_Distance(ST_GeogFromText(ST_AsText(nodes.geom)), ST_MakePoint("+latlon.getLon()+", "+latlon.getLat()+") )"
            + "limit 1";
        */
       
                String query = "select nodes.id " +
            " from ways " +
            " join way_nodes on ways.id = way_nodes.way_id " +
            " join nodes on way_nodes.node_id = nodes.id " +
            " join extra_all_boundaries on ST_Covers(extra_all_boundaries.boundary, ST_GeogFromText(ST_AsText(ST_MakePoint("+latlon.getLon()+","+latlon.getLat()+")))) " +            
            " where ways.id = " + way.getOsmId() +
            " and extra_all_boundaries.relation_id = "+municip.getOsmId()+" and ST_Covers(extra_all_boundaries.boundary,nodes.geom) " +
            (exclude.size() > 0 ? " and not nodes.id in (" + String.join(",", exclude) + ") " : "") + 
            "order by ST_Distance(ST_GeogFromText(ST_AsText(nodes.geom)), ST_GeogFromText(ST_AsText(ST_MakePoint("+latlon.getLon()+","+latlon.getLat()+"))) )"
            + "limit 1";
        
        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + ":" + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword + "&" + 
                "cancelSignalTimeout=60";
        
        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc)) { 
            
            pgresConn.createStatement().execute("set statement_timeout to 60000");
            
            try (
                java.sql.Statement st = pgresConn.createStatement();
                ResultSet rs = st.executeQuery(query);   
            ) {
                if(rs.next()) 
                    return new Node(rs.getString(1));
                else
                    return null;
            } catch(Exception e) {
                throw new Exception("ERROR: NODE");
            }
            
        } catch(Exception e) {
            throw new Exception("ERROR: NODE");
        }
        
    }
    
}

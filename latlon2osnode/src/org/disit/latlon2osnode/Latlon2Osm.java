/** 
 * Licensed under GNU Affero General Public License v3.0
 */
package org.disit.latlon2osnode;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Properties;

/**
 * @author Mirco Soderi @ DISIT DINFO UNIFI (mirco.soderi at unifi dot it)
 */
public class Latlon2Osm extends HttpServlet {

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
     * methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException  {
        
        response.setContentType("text/plain;charset=UTF-8");
        
        try (PrintWriter out = response.getWriter()) {

            if (
                null == request.getParameter("lat") || 
                null == request.getParameter("lon")
            ) {
                out.println("ERROR");
                out.println("Invalid arguments.");
                return;
            } else {
            }

            String returnType = "node";
            if(null != request.getParameter("type")) {
                switch(request.getParameter("type")) {
                    case "region":
                        returnType = "region";
                        break;
                    case "county":
                        returnType = "county";
                        break;
                    case "municipality":
                        returnType = "municipality";
                        break;
                    case "way":
                        returnType = "way";              
                }
            }
            
            int restrictions = 0;
            if(null != request.getParameter("restrictions")) {
                   if(request.getParameter("restrictions").matches("\\d+")) {
                        restrictions = Integer.parseInt(
                                request.getParameter("restrictions"));
                   }
                   else {
                        out.println("ERROR");
                        out.println("Invalid arguments.");
                        return;
                   }
            }
            
            ArrayList<String> excludeNodes = new ArrayList<>();
            if(request.getParameter("exclude_nodes") != null) {
                excludeNodes = new ArrayList<>(Arrays.asList(request.getParameter("exclude_nodes").split(",")));
            }
            
            ArrayList<String> excludeWays = new ArrayList<>();
            if(request.getParameter("exclude_ways") != null) {
                excludeWays = new ArrayList<>(Arrays.asList(request.getParameter("exclude_ways").split(",")));
            }
            
            Node pt = new Node (
                    Double.parseDouble(request.getParameter("lat")), 
                    Double.parseDouble(request.getParameter("lon"))
            );

            Properties p = new Properties();
            String cfgFile = getServletConfig().getInitParameter("CfgFileUserHomeRelPath");
            if(null != request.getParameter("cfg")) {
                cfgFile = request.getParameter("cfg");
            }
            try (
                    FileInputStream file = new FileInputStream(System.getProperty("user.home")+
                    cfgFile)) {
                p.load(file);
            }
            catch(Exception e) { 
                out.println("ERROR");
                out.println(e.getMessage());
                return;
            }

      
            SearchEngine engine = new SearchEngine(
                    p.getProperty("pPostgresHostname"),
                    p.getProperty("pPostgresPort"),
                    p.getProperty("pPostgresDatabase"),
                    p.getProperty("pPostgresUsername"),
                    p.getProperty("pPostgresPassword")
            );
            
            pt = engine.validate(pt);

            if("region".equals(returnType)){
                
                Region region = engine.getRegion(pt);
                
                out.print(region);
                
                return;
                
            }
            
            if("county".equals(returnType)){
                
                County county = engine.getCounty(pt);
                
                out.print(county);
                
                return;
                
            }
            
            if("municipality".equals(returnType)){
                
                Municipality municipality = engine.getMunicipality(pt);
                
                out.print(municipality);
                
                return;
                
            }
            
            if("way".equals(returnType)) {
            
                Municipality municipality = engine.getMunicipality(pt);
                
                Way way = engine.getWay(municipality, pt, restrictions, excludeWays);
                            
                out.print(way);

                return;

            }
            
            if("node".equals(returnType)) {
            
                Municipality municipality = engine.getMunicipality(pt);
                
                Way way = engine.getWay(municipality, pt, restrictions, excludeWays);
                
                Node node = engine.getNode(municipality, way, pt, excludeNodes);
                
                while(node == null) {
                    excludeWays.add(Integer.toString(way.getOsmId()));
                    way = engine.getWay(municipality, pt, restrictions, excludeWays);
                    node = engine.getNode(municipality, way, pt, excludeNodes);
                }
                
                out.print(node);
                
            }
        }
        catch(Exception e) {
            PrintWriter out = response.getWriter();
            out.println("ERROR");
            out.println(e.getMessage());
            out.flush();
        }
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "This servlet implements the latlon2osnode service, which "
                + "takes latitude and longitude as input, and returns "
                + "the region, county, municipality, way, or node to be "
                + "associated to the point, depending of what the user "
                + "specified in the \"type\" input parameter.";
    }// </editor-fold>

}

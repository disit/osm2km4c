/* OSM2KM4C
   Copyright (C) 2017 DISIT Lab http://www.disit.org - University of Florence

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation, either version 3 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>. */
   
package org.disit.latlon2osnode;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.PrintWriter;
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
            
            Node pt = new Node (
                    Double.parseDouble(request.getParameter("lat")), 
                    Double.parseDouble(request.getParameter("lon"))
            );

            Properties p = new Properties();
            try (FileInputStream file = new FileInputStream(System.getProperty("user.home")+
                    getServletConfig().getInitParameter("CfgFileUserHomeRelPath"))) {
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
                
                Way way = engine.getWay(municipality, pt, restrictions);
                            
                out.print(way);

                return;

            }
            
            if("node".equals(returnType)) {
            
                Municipality municipality = engine.getMunicipality(pt);
                
                Way way = engine.getWay(municipality, pt, restrictions);
                
                Node node = engine.getNode(municipality, way, pt);
                
                out.print(node);
                
            }
        }
        catch(Exception e) {
            PrintWriter out = response.getWriter();
            out.println("ERROR");
            out.println(e.getMessage());
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

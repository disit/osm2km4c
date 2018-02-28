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

/**
 * @author Mirco Soderi @ DISIT DINFO UNIFI (mirco.soderi at unifi dot it)
 */
public class Node {
    
    private String osmId;
    private double lat;
    private double lon;
        
    public Node() {
        this.osmId = new String();
        this.lat = -1;
        this.lon = -1;
    }
    
    public Node(double lat, double lon) {
        this.osmId = new String();
        this.lat = lat;
        this.lon = lon;
    }
    
    public Node(String osmId) {
        this.osmId = osmId;
        this.lat = -1;
        this.lon = -1;
    }
        
    public Node(String osmId, double lat, double lon) {
        this.osmId = osmId;
        this.lat = lat;
        this.lon = lon;
    }

    public double getLat() {
        return lat;
    }

    public void setLat(double lat) {
        this.lat = lat;
    }

    public double getLon() {
        return lon;
    }

    public void setLon(double lon) {
        this.lon = lon;
    }

    public String getOsmId() {
        return osmId;
    }

    public void setOsmId(String osmId) {
        this.osmId = osmId;
    }
    
    @Override
    public String toString() {
        if(!osmId.isEmpty()) return osmId; 
        else return Double.toString(lat)+","+Double.toString(lon);
    }
    
    
}

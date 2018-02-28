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
public class Municipality implements Boundary {
    
    private int osmId;
    private String centroid;
    private String boundary;
    
    public Municipality() {
        osmId = -1;
        centroid = new String();
        boundary = new String();
    }
    
    public Municipality(int osmId, String centroid, String boundary) {
        this.osmId = osmId;
        this.centroid = centroid;
        this.boundary = boundary;
    }

    public int getOsmId() {
        return osmId;
    }

    public void setOsmId(int osmId) {
        this.osmId = osmId;
    }

    public String getCentroid() {
        return centroid;
    }

    public void setCentroid(String centroid) {
        this.centroid = centroid;
    }

    public String getBoundary() {
        return boundary;
    }

    public void setBoundary(String border) {
        this.boundary = border;
    }
        
    @Override
    public String toString() {
        return Integer.toString(osmId);
    }
    
}

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
   
package org.disit.serv2osm;

import java.math.BigInteger;

/**
 * @author Mirco Soderi @ DISIT DINFO UNIFI (mirco.soderi at unifi dot it)
 */
public class ReconciliationResult {
    
    String isInRoad;
    String hasAccess;
    
    public ReconciliationResult(String isInRoad, String hasAccess) {
        this.isInRoad = isInRoad;
        this.hasAccess = hasAccess;
    }
    
    public ReconciliationResult(BigInteger wayId, BigInteger longroadId, BigInteger squareId, BigInteger nodeId) {
        String roadURI = "";
        if(longroadId == null && squareId == null) {
            roadURI+="http://www.disit.org/km4city/resource/OS";
            for(int i = 0; i < 11-wayId.toString().length();i++) {
                roadURI+="0";
            }
            roadURI+=wayId.toString();
            roadURI+="SR";
        }
        else if(longroadId != null) {
            roadURI+="http://www.disit.org/km4city/resource/OS";
            for(int i = 0; i < 11-longroadId.toString().length();i++) {
                roadURI+="0";
            }
            roadURI+=longroadId.toString();
            roadURI+="LR";
        }
        else {
            roadURI+="http://www.disit.org/km4city/resource/OS";
            for(int i = 0; i < 11-squareId.toString().length();i++) {
                roadURI+="0";
            }
            roadURI+=squareId.toString();
            roadURI+="SQ";
        }
        this.isInRoad = roadURI;
        
        String entryURI = "";
            entryURI+="http://www.disit.org/km4city/resource/OS";
            for(int i = 0; i < 11-nodeId.toString().length();i++) {
                entryURI+="0";
            }
            entryURI+=nodeId.toString();
            entryURI+="NE";
            this.hasAccess = entryURI;
            
    }

    public String getIsInRoad() {
        return isInRoad;
    }

    public void setIsInRoad(String isInRoad) {
        this.isInRoad = isInRoad;
    }

    public String getHasAccess() {
        return hasAccess;
    }

    public void setHasAccess(String hasAccess) {
        this.hasAccess = hasAccess;
    }
    
}

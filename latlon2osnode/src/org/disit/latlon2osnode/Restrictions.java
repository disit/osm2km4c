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
public class Restrictions {
    
    // Below here, an integer value is associated to each restriction, and it
    // must be interpreted as a position. The restriction is active if in the 
    // binary representation of the "restrictions" input parameter, a 1 appears  
    // at the position associated to the restriction.
    
    public static int MUST_BE_REACHABLE_BY_FOOT = 0;
    
    public static boolean isActive(int thisRestriction, int withinTheseRestrictions) {
        return '1' == (Integer.toBinaryString(withinTheseRestrictions).toCharArray())[thisRestriction];
    }
}

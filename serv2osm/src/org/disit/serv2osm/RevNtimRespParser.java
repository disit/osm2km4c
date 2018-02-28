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

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

/**
 * @author Mirco Soderi @ DISIT DINFO UNIFI (mirco.soderi at unifi dot it)
 */
public class RevNtimRespParser extends DefaultHandler {
    
    private String road = new String();
    boolean readTxt = false;
    boolean done = false;
    
    @Override
    public void startElement(String uri, 
    String localName, String qName, Attributes attributes)
    throws SAXException { 
        if(!done) if("road".equals(qName)) {
            readTxt = true;
        }
    }
    
    @Override
    public void characters(char ch[], 
      int start, int length) throws SAXException {
        if(!done) if (readTxt) {
            road = new String(ch,start,length);
            done = true;
        }
    }

    public String getRoad() {
        return road;
    }

    public void setRoad(String road) {
        this.road = road;
    }

    
}

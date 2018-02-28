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

import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

/**
 * @author Mirco Soderi @ DISIT DINFO UNIFI (mirco.soderi at unifi dot it)
 */
public class NtimRespParser extends DefaultHandler{
    
    private String elementType = new String();
    private String elementId = new String();
    private String displayName = new String();
    boolean done = false;
    private static final Logger LOGGER =
	  Logger.getLogger(Serv2osm.class.getName());
    
    @Override
    public void startElement(String uri, 
    String localName, String qName, Attributes attributes)
    throws SAXException { 
        
        LOGGER.setLevel(Level.OFF);
        ConsoleHandler handler = new ConsoleHandler();
        handler.setLevel(Level.OFF);
        LOGGER.addHandler(handler);
            
        if(!done) {
           if("place".equals(qName)) {
               elementType = attributes.getValue("osm_type");
               elementId = attributes.getValue("osm_id");
               displayName = attributes.getValue("display_name");
               if("node".equals(elementType) || "way".equals(elementType)) done = true;
           }
        }
    }

    public String getElementType() {
        return elementType;
    }

    public void setElementType(String elementType) {
        this.elementType = elementType;
    }

    public String getElementId() {
        return elementId;
    }

    public void setElementId(String elementId) {
        this.elementId = elementId;
    }
    
    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }
    
}

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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.math.BigInteger;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Scanner;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.eclipse.rdf4j.model.IRI;
import org.eclipse.rdf4j.model.Model;
import org.eclipse.rdf4j.model.Value;
import org.eclipse.rdf4j.model.ValueFactory;
import org.eclipse.rdf4j.model.impl.SimpleValueFactory;
import org.eclipse.rdf4j.model.util.ModelBuilder;
import org.eclipse.rdf4j.query.BindingSet;
import org.eclipse.rdf4j.query.QueryLanguage;
import org.eclipse.rdf4j.query.TupleQuery;
import org.eclipse.rdf4j.query.TupleQueryResult;
import org.eclipse.rdf4j.repository.Repository;
import org.eclipse.rdf4j.repository.RepositoryConnection;
import org.eclipse.rdf4j.rio.RDFFormat;
import org.eclipse.rdf4j.rio.RDFHandlerException;
import org.eclipse.rdf4j.rio.RDFWriter;
import org.eclipse.rdf4j.rio.Rio;
import org.json.JSONObject;
import virtuoso.rdf4j.driver.VirtuosoRepository;

/**
 * @author Mirco Soderi @ DISIT DINFO UNIFI (mirco.soderi at unifi dot it)
 */
public class Serv2osm {

    private static String pVirtuosoHost4Serv = new String();
    private static String pVirtuosoPort4Serv = new String();
    private static String pVirtuosoUsername4Serv = new String();
    private static String pVirtuosoPassword4Serv = new String();
    private static String pVirtuosoGraph4Serv = new String();
    private static String pVirtuosoHost4OSM = new String();
    private static String pVirtuosoPort4OSM = new String();
    private static String pVirtuosoUsername4OSM = new String();
    private static String pVirtuosoPassword4OSM = new String();
    private static String pVirtuosoGraph4OSM = new String();
    private static String pPostgresHost4OSM = new String();
    private static String pPostgresPort4OSM = new String();
    private static String pPostgresUsername4OSM = new String();
    private static String pPostgresPassword4OSM = new String();
    private static String pPostgresDatabase4OSM = new String();
    private static String pTarget = new String();
    private static String pServEndpoint = new String();
    private static String pOutput = new String();
    private static String pLog = new String();
    private static String pIdle = new String();
    private static final Logger LOGGER =
	  Logger.getLogger(Serv2osm.class.getName());
    private static final ModelBuilder RDF_BUILDER = new ModelBuilder();
    private static int totalNumberOfReconciliationAttempts = 0;
    private static int reconciliableByAddress = 0;
    private static int reconciliationSuccessByAddress = 0;
    private static int reconciliationFailureByAddress = 0;
    private static int notReconciliableByAddress = 0;
    private static int attemptedReconciliationByGeometry = 0;
    private static int reconciliableByGeometry = 0;
    private static int reconciliationSuccessByGeometry = 0;
    private static int reconciliationFailureByGeometry = 0;
    private static int notReconciliableByGeometry = 0;
    private static int reconciliationSuccessByGeometryRoadOnly;
        
    /**
     * @param args the command line arguments
     * @throws java.lang.Exception
     */
    public static void main(String[] args) throws Exception {
        
        readArgs(args);
        
        setLogLevel();
        
        LOGGER.log(Level.INFO, "Reconciliation started.");

        RDF_BUILDER.setNamespace("km4c","http://www.disit.org/km4city/schema#");

        Repository km4cRepo;
        if(pVirtuosoGraph4Serv.isEmpty()) {
            km4cRepo = new VirtuosoRepository("jdbc:virtuoso://".
                concat(pVirtuosoHost4Serv).
                concat(pVirtuosoPort4Serv),pVirtuosoUsername4Serv,
                pVirtuosoPassword4Serv);
        }
        else {
            km4cRepo = new VirtuosoRepository("jdbc:virtuoso://".
                concat(pVirtuosoHost4Serv).
                concat(pVirtuosoPort4Serv),
                pVirtuosoUsername4Serv,pVirtuosoPassword4Serv, 
                    pVirtuosoGraph4Serv);
        }
        
        km4cRepo.initialize();
        
        try ( RepositoryConnection km4cRepoConn = km4cRepo.getConnection() ) {
            
            String targetSparql = "SELECT DISTINCT ?s { ?s " +
                        "schema:name ?n ; " +
                        "schema:addressLocality ?l ;" +
                        "schema:streetAddress ?a ;" +
                        "km4c:houseNumber ?h ." +
                    " } ";
            
            if(!pTarget.isEmpty()) {
                byte[] bTargetSparql = Files.readAllBytes(Paths.get(pTarget));
                targetSparql = new String(bTargetSparql);
            }
            
            TupleQuery targetQuery = km4cRepoConn.
                    prepareTupleQuery(QueryLanguage.SPARQL, targetSparql);
            
            try ( TupleQueryResult result = targetQuery.evaluate() ) {

                while (result.hasNext()) {
                             
                    BindingSet bindingSet = result.next();

                    Value targetURI = bindingSet.getValue("s");
                    
                    LOGGER.log(Level.FINE, "Reconciliation attempt started for: {0}",
                    new String[]{targetURI.stringValue()});
                    
                    totalNumberOfReconciliationAttempts++;
                    
                    boolean reconciliated = false;
                    
                    // Per ogni URI di servizio da riconciliare
                    // guardo prima di tutto se riesco a riconciliarlo tramite
                    // l'indirizzo 
                    
                    String oneTargetAddr = "select ?n ?l ?a ?h { " +
                        "<" + targetURI.stringValue() + "> " +
                        "schema:name ?n ;" +
                        "schema:addressLocality ?l ;" +
                        "schema:streetAddress ?a . " +
                        " optional { " +
                        "<" + targetURI.stringValue() + "> " +
                        "km4c:houseNumber ?h ; " +
                        "geo:lat ?lat ; " +    
                        "geo:long ?long " +    
                        " } }";
                    
                    TupleQuery addrQuery = km4cRepoConn.
                        prepareTupleQuery(QueryLanguage.SPARQL, oneTargetAddr);
                    
                    try (TupleQueryResult addrResult = addrQuery.evaluate()) {
                        
                        if(addrResult.hasNext()) {
                            
                            reconciliableByAddress++;
                            
                             BindingSet addrSet = addrResult.next();

                             Value name = addrSet.getValue("n");
                             Value addressLocality = addrSet.getValue("l");
                             Value streetAddress = addrSet.getValue("a");
                             Value houseNumber = addrSet.getValue("h");
                             Value lat = addrSet.getValue("lat");
                             Value lon = addrSet.getValue("long");
                             
                             reconciliated = reconciliate(targetURI.stringValue(), 
                                addressLocality.stringValue(), 
                                streetAddress.stringValue(),
                                houseNumber != null ? houseNumber.stringValue() : "",
                                lat != null ? lat.stringValue() : "",
                                lon != null ? lon.stringValue() : ""
                             );
                             
                             if(reconciliated) {
                                 reconciliationSuccessByAddress++;
                             }
                             else {
                                 reconciliationFailureByAddress++;
                             }

                        } 
                        else {
                            notReconciliableByAddress++;
                        }
                        
                        addrResult.close();
                        
                    }
                    
                    // E per quelli che non sono riuscito a riconciliare sulla
                    // base dell'indirizzo, vado a vedere
                    // se avessero una geometry, e se ce l'hanno, utilizzo 
                    // quella per fare la riconciliazione. 
                    
                    if(!reconciliated) {
                        
                        attemptedReconciliationByGeometry++;
                       
                        oneTargetAddr = "select ?lat ?long { " +
                        "<" + targetURI.stringValue() + "> " +
                        "geo:lat ?lat; " +
                        "geo:long ?long " +
                        "}";
                    
                        addrQuery = km4cRepoConn.
                            prepareTupleQuery(QueryLanguage.SPARQL, oneTargetAddr);

                        try (TupleQueryResult addrResult = addrQuery.evaluate()) {

                            if(addrResult.hasNext()) {

                                reconciliableByGeometry++;

                                 BindingSet addrSet = addrResult.next();

                                 Value lat = addrSet.getValue("lat");
                                 Value lon = addrSet.getValue("long");

                                 String streetAddress = getStreetAddress( 
                                    lat.stringValue(), 
                                    lon.stringValue()
                                 );
                                 
                                 String addressLocality = getAddressLocality(
                                    lat.stringValue(), 
                                    lon.stringValue()
                                 );
                                 
                                 if(!(streetAddress == null || streetAddress.trim().isEmpty() ||
                                         addressLocality == null || addressLocality.trim().isEmpty())) {
                                     
                                     LOGGER.log(Level.FINE, "Attempting a reconciliation using the service georeferentiation.");
                                     
                                     reconciliated = reconciliate(targetURI.stringValue(), 
                                        addressLocality, 
                                        streetAddress,
                                        "",
                                        lat.stringValue(),
                                        lon.stringValue()
                                     );
                                     
                                    if(reconciliated) {
                                        reconciliationSuccessByGeometry++;
                                    }
                                    else {
                                        LOGGER.log(Level.FINE, "Attempting a partial reconciliation using the service georeferentiation.");
                                        reconciliated = reconciliateRoadOnlyByGeometry(
                                                targetURI.stringValue(), addressLocality, streetAddress);
                                        if(reconciliated) {
                                            reconciliationSuccessByGeometry++;
                                            reconciliationSuccessByGeometryRoadOnly++;
                                            LOGGER.log(Level.FINE, "Success. The road was reconciliated using the service georeferentiation.");
                                        }
                                        else {
                                            reconciliationFailureByGeometry++;
                                            LOGGER.log(Level.FINE, "Failed. The partial reconciliation also was impossible.");
                                        }

                                    }
                                 }
                                 

                            }
                            else
                            {
                                notReconciliableByGeometry++;
                            }

                            addrResult.close();

                        }
                    
                    }
                    
                    LOGGER.log(Level.FINE, "Reconciliation attempt ended for: {0}",
                    new String[]{targetURI.stringValue()});

                }
                
                result.close();
                
            }
            
            Model rdfModel = RDF_BUILDER.build();
            
            persistModel(rdfModel);
            
            km4cRepoConn.close();
            
        }
        
        km4cRepo.shutDown();

    }
    
    private static boolean reconciliateRoadOnlyByGeometry(String targetURI, 
            String municipality, String extendRoadName) {
        
        Repository km4cRepo;
        
        if(pVirtuosoGraph4OSM.isEmpty()) {
            km4cRepo = new VirtuosoRepository("jdbc:virtuoso://".
        concat(pVirtuosoHost4OSM).
        concat(pVirtuosoPort4OSM),pVirtuosoUsername4OSM,pVirtuosoPassword4OSM);
        }
        else
        {
            km4cRepo = new VirtuosoRepository("jdbc:virtuoso://".
        concat(pVirtuosoHost4OSM).
        concat(pVirtuosoPort4OSM),pVirtuosoUsername4OSM,pVirtuosoPassword4OSM, 
                pVirtuosoGraph4OSM);
        }
                
        try ( RepositoryConnection km4cRepoConn = km4cRepo.getConnection() ) { 
            
            String reconSparql = "select distinct str(?s) as ?road { graph ?g { " +
                "?s a km4c:Road ; " +
                "km4c:extendName \""+extendRoadName+"\" ; " +
                "km4c:inMunicipalityOf ?m . " +
                "?m foaf:name \""+municipality+"\" . " +
                "} }";
            
            TupleQuery reconQuery = km4cRepoConn.
                    prepareTupleQuery(QueryLanguage.SPARQL, reconSparql);
            
            try ( TupleQueryResult result = reconQuery.evaluate() ) {

                if (result.hasNext()) {
                    
                    BindingSet bindingSet = result.next();

                    String road = bindingSet.getValue("road").stringValue();
                    
                    ValueFactory vFactory = SimpleValueFactory.getInstance();
                    IRI reconciliatedRoad = vFactory.createIRI(road);

                    RDF_BUILDER.defaultGraph().
                        subject(targetURI).
                        add("km4c:isInRoad", reconciliatedRoad);
                    
                    return true;
                    
                }
                
                result.close();
                
            }
            
            km4cRepoConn.close();
            
        }
        
        km4cRepo.shutDown();
        
        return false;
        
    }
    
    private static void readArgs(String[] args) throws Exception {
        if(args.length == 0) usageGuide();
        
        String currPar = new String();
        for (String arg : args) {
            if (currPar.isEmpty()) {
                currPar = arg;
            }
            else
            {
                switch (currPar) {
                    case "-h":
                    case "--virt-host-serv":
                        pVirtuosoHost4Serv = arg;
                        break;
                    case "-p":
                    case "--virt-port-serv":
                        pVirtuosoPort4Serv = arg;
                        break;
                    case "-u":
                    case "--virt-user-serv":
                        pVirtuosoUsername4Serv = arg;
                        break;
                    case "-P":
                    case "--virt-pwd-serv":
                        pVirtuosoPassword4Serv = arg;
                        break;
                    case "-sg":
                    case "--virt-graph-serv":
                        pVirtuosoGraph4Serv = arg;
                        break;
                    case "-oh":
                    case "--virt-host-osm":
                        pVirtuosoHost4OSM = arg;
                        break;
                    case "-op":
                    case "--virt-port-osm":
                        pVirtuosoPort4OSM = arg;
                        break;
                    case "-ou":
                    case "--virt-user-osm":
                        pVirtuosoUsername4OSM = arg;
                        break;
                    case "-oP":
                    case "--virt-pwd-osm":
                        pVirtuosoPassword4OSM = arg;
                        break;
                    case "-rg":
                    case "--virt-graph-osm":
                        pVirtuosoGraph4OSM = arg;
                        break;
                    case "-ph":
                    case "--pgre-host-osm":
                        pPostgresHost4OSM = arg;
                        break;
                    case "-pp":
                    case "--pgre-port-osm":
                        pPostgresPort4OSM = arg;
                        break;
                    case "-pu":
                    case "--pgre-user-osm":
                        pPostgresUsername4OSM = arg;
                        break;
                    case "-pP":
                    case "--pgre-pwd-osm":
                        pPostgresPassword4OSM = arg;
                        break;
                    case "-pd":
                    case "--pgre-db-osm":
                        pPostgresDatabase4OSM = arg;
                        break;
                    case "-t":
                    case "--target-query":
                        pTarget = arg;
                        break;
                    case "-s":
                    case "--service-endpoint":
                        pServEndpoint = arg;
                        break;
                    case "-o":
                    case "--output":
                        pOutput = arg;
                        break;
                    case "-l":
                    case "--log":
                        pLog = arg;
                        break;
                    case "-i":
                    case "--idle":
                        pIdle = arg;
                        break;
                    default:
                        throw new Exception("Unknown argument: "+currPar);
                }
                currPar = new String();
            }
        }
        
        if(pVirtuosoHost4Serv.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Virtuoso hostname for services. " +
                "Launch without arguments for usage guide."); 
        }
        if( ! ( pVirtuosoPort4Serv.isEmpty() || isNumeric(pVirtuosoPort4Serv) ) ) { 
            throw new Exception("Invalid argument: Virtuoso port for services. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(!pVirtuosoPort4Serv.isEmpty()) pVirtuosoPort4Serv = ":".
                concat(pVirtuosoPort4Serv);
        if(pVirtuosoUsername4Serv.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Virtuoso username for services. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(pVirtuosoPassword4Serv.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Virtuoso password for services. " + 
                    "Launch without arguments for usage guide."); 
        }
        
        if(pVirtuosoHost4OSM.isEmpty()) { 
            throw new Exception(
                "Missing argument: Virtuoso hostname for OSM street graph. " +
                "Launch without arguments for usage guide."); 
        }
        if( ! ( pVirtuosoPort4OSM.isEmpty() || isNumeric(pVirtuosoPort4OSM) ) ) { 
            throw new Exception(""
                + "Invalid argument: Virtuoso port for OSM street graph. " + 
                "Launch without arguments for usage guide."); 
        }
        if(!pVirtuosoPort4OSM.isEmpty()) pVirtuosoPort4OSM = ":".concat(pVirtuosoPort4OSM);
        if(pVirtuosoUsername4OSM.isEmpty()) { 
            throw new Exception(
                "Missing argument: Virtuoso username for OSM street map. " + 
                "Launch without arguments for usage guide."); 
        }
        if(pVirtuosoPassword4OSM.isEmpty()) { 
            throw new Exception(
                "Missing argument: Virtuoso password for OSM street map. " + 
                "Launch without arguments for usage guide."); 
        }
        
        
        if(!pTarget.isEmpty()) {
            File f = new File(pTarget);
            if(!(f.exists() && !f.isDirectory())) { 
                throw new Exception("Invalid argument: target query. " + 
                    "Launch without arguments for usage guide.");
            }
        }
        
        if(pServEndpoint.isEmpty()) {
            throw new Exception("Missing argument: Service endpoint. " + 
                "Launch without arguments for usage guide."); 
        }
        
        if((!pIdle.isEmpty()) && (!isNumeric(pIdle))) {
            throw new Exception("Invalid argument: Idle time. " + 
                    "Launch without arguments for usage guide."); 
        }
        
        if(pTarget.isEmpty() && pVirtuosoGraph4Serv.isEmpty()) {
            Scanner scanner = new Scanner(System.in);
            System.out.println("Target the whole RDF store (yes/no)?");
            String isSure = scanner.next();
            if(!("yes".equals(isSure))) {
                System.exit(0);
            }
        }
        
        if(!pPostgresPort4OSM.isEmpty()) pPostgresPort4OSM = ":".
                concat(pPostgresPort4OSM);
        
    }
    
    private static void usageGuide() {
        
        System.out.println(
            "SERV2OSM USAGE GUIDE                                          \n" +
            "--------------------------------------------------------------\n" +
            "This command line tool attempts to associate a km4c:Road and  \n" +
            "a km4c:Entry to a service on the basis of its address obtained\n" +                    
            "by accessing addressLocality, streetAddress and houseNumber   \n" +          
            "properties of the service instance stored in the RDF database.\n" +        
            "                                                              \n" +
            "List of arguments:                                            \n" +
            "-h, --virt-host-serv: address of the Virtuoso RDF store       \n" +
            "    instance where services are located                       \n" +
            "-p, --virt-port-serv: port on which the Virtuoso RDF store    \n" +
            "    instance where services are located is listening          \n" +
            "-u, --virt-user-serv: username for logging to the Virtuoso    \n" +
            "    RDF store instance where services are located             \n" +
            "-P, -virt-pwd-serv: password for logging to the Virtuoso      \n" +
            "    RDF store instance where services are located             \n" +
            "-sg, --virt-graph-serv: graph where the triples about the     \n" +
            "    services that have to be reconciliated are located        \n" +
            "-oh, --virt-host-osm: address of the Virtuoso RDF store       \n" +
            "    instance where OSM street graph is located                \n" +
            "-op, --virt-port-osm: port on which the Virtuoso RDF store    \n" +
            "    instance where OSM street graph is located is listening   \n" +
            "-ou, --virt-user-osm: username for logging to the Virtuoso    \n" +
            "    RDF store instance where OSM street graph is located      \n" +
            "-oP, -virt-pwd-osm: password for logging to the Virtuoso      \n" +
            "    RDF store instance where OSM street graph is located      \n" +
            "-rg, --virt-graph-osm: graph where the triples about roads,   \n" +
            "    civic numbers and entries are located                     \n" +
            "-t, --target-query: an optional path to a text file containing\n" +
            "    a SPARQL query that extracts in column ?s the list of the \n" +
            "    URIs of the services that have to be reconciliated.       \n" +
            "    Defaults to the whole services graph.                     \n" +
            "-s, --service-endpoint: the base URL of the REST service that \n" +
            "    gets a human-readable address and returns the URI of the  \n" +
            "    km4c:StreetNumber instance to be associated to the service\n" +
            "-o, --output: the path to the output file where the triples   \n" +                    
            "    that provide a value for the properties isInRoad and      \n" +                       
            "    hasAccess of the target services will be stored           \n" +
            "-l, --log: optional log level, allowed valorizations are:     \n" +                    
            "    off, minimal, verbose. Defaults to minimal.               \n" +
            "-i, --idle: optional idle time before querying the Virtuoso   \n" +                    
            "    RDF store or the address search service, in milliseconds  \n" 
        );
        
        System.exit(0);
        
    }
    
    private static boolean isNumeric(String str)  
    {  
      try  
      {  
        double d = Double.parseDouble(str);  
      }  
      catch(NumberFormatException nfe)  
      {  
        return false;  
      }  
      return true;  
    }
    
    private static String askCivicNumber 
        (String locality, String street, String houseNumber) 
        throws Exception {
            
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
            
        // Call to service Address/POI search by text
        // http://www.disit.org/drupal/?q=home&axoid=urn%3Aaxmedis%3A00000%3Aobj%3A1f27dffd-0d3a-44a5-9e2b-194dd85c3be3

        String urlStr = pServEndpoint + "search=" + URLEncoder.encode(
            street + " " + houseNumber + " " + locality, "UTF-8") + 
            "&searchMode=AND&excludePOI=true&maxResults=1000";
        
        URL servURL = new URL(urlStr);

        HttpURLConnection servConn = 
                (HttpURLConnection) servURL.openConnection();

        servConn.setRequestMethod("GET");

        String response = new String(); 

        try (BufferedReader in = new BufferedReader(
                new InputStreamReader(servConn.getInputStream()))) {
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                response+=inputLine;
            }
        }

        return response;
            
    }

    private static void persistModel(Model model) 
            throws FileNotFoundException {
        
        File outf = new File(pOutput);
        FileOutputStream out = new FileOutputStream(outf);
        RDFWriter writer = Rio.createWriter(RDFFormat.N3, out);
        try {
            writer.startRDF();
            model.forEach((st) -> {
                writer.handleStatement(st);
            });
            writer.endRDF();
            LOGGER.log(Level.INFO,"Reconciliation complete. "
                    + "{0} service reconciliations were attempted, "
                    + "in {1} cases a valid street address was available, "
                    + "in {2} of such cases the reconciliation by address succeeded "
                    + "while in {3} of such cases it failed, "
                    + "so for {4} services the reconciliation by geometry was taken into consideration, "
                    + "for {5} of such services a geometry was available, "
                    + "for {6} of such services the reconciliation by geometry succeeded "
                    + "(in {7} cases the road only could be reconciliated anyway) "
                    + "while for {8} of them it failed, "
                    + "so a total of {9} services were reconciliated some way, "
                    + "while {10} services could not be reconciliated at all. "
                    + "Triples are in {11}. ",
                    new String[]{ Integer.toString(totalNumberOfReconciliationAttempts),
                        Integer.toString(reconciliableByAddress),
                        Integer.toString(reconciliationSuccessByAddress),
                        Integer.toString(reconciliationFailureByAddress),
                        Integer.toString(attemptedReconciliationByGeometry),
                        Integer.toString(reconciliableByGeometry),
                        Integer.toString(reconciliationSuccessByGeometry),
                        Integer.toString(reconciliationSuccessByGeometryRoadOnly),
                        Integer.toString(reconciliationFailureByGeometry),
                        Integer.toString(reconciliationSuccessByAddress+reconciliationSuccessByGeometry),
                        Integer.toString(totalNumberOfReconciliationAttempts-reconciliationSuccessByAddress-reconciliationSuccessByGeometry),
                        outf.getAbsolutePath()});
          } catch (RDFHandlerException e) {
            throw new RuntimeException(e);
        }

    }

    private static boolean reconciliate( String targetURI,
            String addressLocality, String streetAddress, String civicNumber,
            String lat, String lon ) 
         {
        try {
        
            ReconciliationResult result = null;
            String servResponse;
            
            if(!civicNumber.trim().isEmpty()) {
            String[] aCivicNumber = civicNumber.split("-");
        String nCivicNumber = aCivicNumber[0].replaceAll("[^\\d.]", "");
        String eCivicNumber = aCivicNumber[0].replaceAll("[^A-Za-z]+", "");
        if(eCivicNumber.length() > 1) eCivicNumber = eCivicNumber.substring(0,1);
        String iCivicNumber = nCivicNumber.concat(eCivicNumber);
        
        servResponse= askCivicNumber(
            addressLocality, 
            streetAddress, 
            iCivicNumber
        );

        result = parseResponse(servResponse, lat, lon);
        
        if(result == null) {
            LOGGER.log(Level.FINE, "Unable to reconciliate with address: {0} {1} {2}", 
            new String[]{addressLocality, streetAddress, iCivicNumber});
        }
        else
        {
            LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
            new String[]{addressLocality, streetAddress, iCivicNumber});
        }
        
        // Handle dotted toponyms

        if(result == null && streetAddress.contains(".")) {
            String[] aStreetAddress = streetAddress.split(" ");
            String newStreetAddress = new String();
            for (String aStreetAddres : aStreetAddress) {
                if (!aStreetAddres.contains(".")) {
                    newStreetAddress += aStreetAddres + " ";
                }
            }
            if(!newStreetAddress.equals(streetAddress)) {

                streetAddress = newStreetAddress;

                servResponse= askCivicNumber(
                    addressLocality, 
                    streetAddress, 
                    iCivicNumber
                );

                LOGGER.log(Level.FINE, 
                    "Attempting with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});

                result = parseResponse(servResponse, lat, lon);

                if(result != null) {
                    LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});
                }
                else
                {
                    LOGGER.log(Level.FINE, 
                        "Unable to reconciliate with address: {0} {1} {2}", 
                        new String[]{addressLocality, streetAddress, 
                        iCivicNumber});
                }
            }
        }
        
        // Handle very long numeric parts of civic numbers

        while(result == null && nCivicNumber.length() > 3) {

            int howMany = (int) Math.ceil(nCivicNumber.length()/2);
            nCivicNumber = nCivicNumber.substring(0, howMany)
                    .replaceFirst("^0+(?!$)", "");
            iCivicNumber = nCivicNumber.concat(eCivicNumber);

            servResponse= askCivicNumber(
                addressLocality, 
                streetAddress, 
                iCivicNumber
            );

            LOGGER.log(Level.FINE, "Attempting with address: {0} {1} {2}", 
                new String[]{addressLocality, streetAddress, iCivicNumber});

            result = parseResponse(servResponse, lat, lon);

            if(result != null) {
                LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
                new String[]{addressLocality, streetAddress, iCivicNumber});
            }
            else
            {
                LOGGER.log(Level.FINE, 
                    "Unable to reconciliate with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, 
                    iCivicNumber});
            }

        }
        
        // Handle alphabet characters 
        
        if(result == null && (!eCivicNumber.isEmpty())) {
            
            iCivicNumber = nCivicNumber + " " + eCivicNumber;
            
            servResponse= askCivicNumber(
                addressLocality, 
                streetAddress, 
                iCivicNumber
            );

            LOGGER.log(Level.FINE, 
                "Attempting with address: {0} {1} {2}", 
                new String[]{addressLocality, streetAddress, iCivicNumber});

            result = parseResponse(servResponse, lat, lon);

            if(result != null) {
                LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
                new String[]{addressLocality, streetAddress, iCivicNumber});
            }
            else
            {
                LOGGER.log(Level.FINE, 
                    "Unable to reconciliate with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, 
                    iCivicNumber});
            }
        }
        
        // Skip to nearby numbers
        int jump = 2;
        
        while(result == null && jump < 10) {
            
            String newnCivicNumber = Integer.toString(
                    Integer.parseInt(nCivicNumber) + jump);
            iCivicNumber = newnCivicNumber+eCivicNumber;
            
            servResponse= askCivicNumber(
                addressLocality, 
                streetAddress, 
                iCivicNumber
            );

            LOGGER.log(Level.FINE, 
                "Attempting with address: {0} {1} {2}", 
                new String[]{addressLocality, streetAddress, iCivicNumber});

            result = parseResponse(servResponse, lat, lon);

            if(result != null) {
                LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
                new String[]{addressLocality, streetAddress, iCivicNumber});
            }
            else
            {
                LOGGER.log(Level.FINE, 
                    "Unable to reconciliate with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, 
                    iCivicNumber});
            }
            
            if(result == null && !eCivicNumber.isEmpty()) {
                
                iCivicNumber = newnCivicNumber+" "+eCivicNumber;

                servResponse= askCivicNumber(
                    addressLocality, 
                    streetAddress, 
                    iCivicNumber
                );

                LOGGER.log(Level.FINE, 
                    "Attempting with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});

                result = parseResponse(servResponse, lat, lon);

                if(result != null) {
                    LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});
                }
                else
                {
                    LOGGER.log(Level.FINE, 
                        "Unable to reconciliate with address: {0} {1} {2}", 
                        new String[]{addressLocality, streetAddress, 
                        iCivicNumber});
                }
            }
            
            if(result == null && jump < Integer.parseInt(nCivicNumber)) {
                newnCivicNumber = Integer.toString(
                    Integer.parseInt(nCivicNumber) - jump);
                iCivicNumber = newnCivicNumber+eCivicNumber;

                servResponse= askCivicNumber(
                    addressLocality, 
                    streetAddress, 
                    iCivicNumber
                );

                LOGGER.log(Level.FINE, 
                    "Attempting with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});

                result = parseResponse(servResponse, lat, lon);

                if(result != null) {
                    LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});
                }
                else
                {
                    LOGGER.log(Level.FINE, 
                        "Unable to reconciliate with address: {0} {1} {2}", 
                        new String[]{addressLocality, streetAddress, 
                        iCivicNumber});
                }
            }
            
            if(result == null && jump < Integer.parseInt(nCivicNumber) 
                    && !eCivicNumber.isEmpty()) {

                iCivicNumber = newnCivicNumber+" "+eCivicNumber;

                servResponse= askCivicNumber(
                    addressLocality, 
                    streetAddress, 
                    iCivicNumber
                );

                LOGGER.log(Level.FINE, 
                    "Attempting with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});

                result = parseResponse(servResponse, lat, lon);
                
                if(result != null) {
                    LOGGER.log(Level.FINE, "Success with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, iCivicNumber});
                }
                else
                {
                    LOGGER.log(Level.FINE, 
                        "Unable to reconciliate with address: {0} {1} {2}", 
                        new String[]{addressLocality, streetAddress, 
                        iCivicNumber});
                }
            }
            
            jump+=2;
            
        }
        
            } // end of if block executed only if street number is available
        
        // Just look for the street ignoring civic number
        
        if(result == null) {

            servResponse= askCivicNumber(addressLocality, streetAddress, "");
            
            result = parseResponse(servResponse, lat, lon);
            
            if(result != null) {
                LOGGER.log(Level.FINE, "Success with address: {0} {1}", 
                new String[]{addressLocality, streetAddress});
            }
            else
            {
                LOGGER.log(Level.FINE, 
                    "Unable to reconciliate with address: {0} {1}", 
                    new String[]{addressLocality, streetAddress});
            }
                            
        }
        
        if(result == null) {
            LOGGER.log(Level.WARNING, "No way to reconciliate with address: {0} {1} {2}", 
                    new String[]{addressLocality, streetAddress, civicNumber});
            return false;
        }
        else {
            ValueFactory vFactory = SimpleValueFactory.getInstance();
            IRI reconciliatedRoad = vFactory.createIRI(result.getIsInRoad());
            IRI reconciliatedEntry = vFactory.createIRI(result.getHasAccess());

            RDF_BUILDER.defaultGraph().
                subject(targetURI).
                add("km4c:isInRoad", reconciliatedRoad);

            RDF_BUILDER.defaultGraph().
                subject(targetURI).
                add("km4c:hasAccess", reconciliatedEntry);
            return true;
        }
        } catch(Exception e) {
            return false;
        }
    }
    
    private static String getStreetAddress( String lat, 
            String lon) throws SQLException {
        
        Connection c = null;
        String relationRoadName = null;
        String squareRoadName = null;
        String wayRoadName = null;
        BigInteger wayId = null;
        
        try {
           

             
           Class.forName("org.postgresql.Driver");
           
            String jdbc = "jdbc:postgresql://" +
                pPostgresHost4OSM + pPostgresPort4OSM + "/" +
                pPostgresDatabase4OSM + "?" +
                "user=" + pPostgresUsername4OSM + "&" +
                "password=" + pPostgresPassword4OSM;
                   
           c = DriverManager.getConnection(jdbc);
           
           c.setAutoCommit(false);

           Statement stmt = c.createStatement();
           
           ResultSet rs = stmt.executeQuery( 
                   "select ways.id id, coalesce(way_name.v,' ') wayRoadName from ways "
                   + "join way_tags on ways.id = way_tags.way_id and way_tags.k = 'highway' and way_tags.v <> 'proposed' "
                   + "left join way_tags way_name on ways.id = way_name.way_id and way_name.k='name'"
                   + "order by ST_Distance(ST_SetSRID(ST_MakePoint("
                   + lon + ","
                   + lat + "),"
                   + "4326),linestring) limit 1;" );
           
           while ( rs.next() ) {
              wayId = new BigInteger(rs.getString("id"));
              wayRoadName = rs.getString("wayRoadName");
           }
           
           rs.close();
           
           stmt.close();
           
           if(wayId != null) {
                    
               stmt = c.createStatement();
           
                rs = stmt.executeQuery( 
                    "select distinct r_name.v relationRoadName " +
                    "  from relations r " +
                    "  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route' " +
                    "  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route' " +
                    "  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network' " +
                    "  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name' " +
                    "  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_id = "+wayId+" and r_ways.member_type = 'W' " +
                    " where COALESCE(r_route.v,'road') = 'road' " +
                    "   and COALESCE(r_network.v, '--') <> 'e-road' ; " 
                );
           
                while ( rs.next() ) {
                   relationRoadName = rs.getString("relationRoadName");

                }

                rs.close();

                stmt.close();
                
                stmt = c.createStatement();
           
                rs = stmt.executeQuery( 
                    "select distinct r_name.v squareRoadName " +
                    "  from relations r " +
                    "  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon' " +
                    "  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian' " +
                    "  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name' " +
                    "  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_id = "+wayId+" and r_ways.member_type = 'W' ;"
                                 );
           
                while ( rs.next() ) {
                   squareRoadName = rs.getString("squareRoadName");

                }

                rs.close();

                stmt.close();
                
           }
           
           c.close();
           
        } 
        catch (ClassNotFoundException | SQLException e) {
           if(c != null && !c.isClosed()) {
               c.close();
           }           
        }
        
        if(squareRoadName != null) return squareRoadName;
        else if(relationRoadName != null) return relationRoadName;
        else return wayRoadName;
            
    }
    
    private static String getAddressLocality( String lat, 
            String lon) throws SQLException {
        
        Connection c = null;
        Statement stmt = null;
        ResultSet rs = null;
        String addressLocality = null;
        
        try {

           Class.forName("org.postgresql.Driver");
           
            String jdbc = "jdbc:postgresql://" +
                pPostgresHost4OSM + pPostgresPort4OSM + "/" +
                pPostgresDatabase4OSM + "?" +
                "user=" + pPostgresUsername4OSM + "&" +
                "password=" + pPostgresPassword4OSM;
                   
           c = DriverManager.getConnection(jdbc);
           
           c.setAutoCommit(false);

           stmt = c.createStatement();
           
           rs = stmt.executeQuery( 
                "select r_name.v addressLocality " +
                "  from relations r " +
                "  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary' " +
                "  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative' " +
                "  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '8' " +
                "  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name' " +
                "  join extra_all_boundaries b on r.id = b.relation_id " +
                "where ST_Covers(b.boundary, ST_SetSRID(ST_MakePoint("+lon+","+lat+"), 4326))"
           );
           
           while ( rs.next() ) {
              addressLocality = rs.getString("addressLocality");
           }
           
           rs.close();
           
           stmt.close();
           
           c.close();
           
        } 
        catch (ClassNotFoundException | SQLException e) {
           if(c != null && !c.isClosed()) {
               c.close();
           }
           if(stmt != null && !stmt.isClosed()) {
               stmt.close();
           }
           if(rs != null && !rs.isClosed()) {
               rs.close();
           }
        }
        
        return addressLocality;
            
    }
    
    private static ReconciliationResult parseResponse(String response, 
            String lat, String lon) 
    throws Exception {
        
        double servLat = 0;
        double servLon = 0;
        double minDist = 0;
        if(!(lat.isEmpty() || lon.isEmpty())) {
            servLat = Double.parseDouble(lat);
            servLon = Double.parseDouble(lon);
        }
                            
        JSONObject resp = new JSONObject(response);
        String cnURI = new String();
        
        for(int i = 0; i < resp.getJSONArray("features").length(); i++) {
            String currCnURI = resp.getJSONArray("features").getJSONObject(i).
                getJSONObject("properties").getString("serviceUri");
            double cnLon = resp.getJSONArray("features").getJSONObject(i).
                getJSONObject("geometry").getJSONArray("coordinates").getDouble(0);
            double cnLat = resp.getJSONArray("features").getJSONObject(i).
                getJSONObject("geometry").getJSONArray("coordinates").getDouble(1);                        
            if(currCnURI.endsWith("NN") || currCnURI.endsWith("WN")) {
                if(cnURI.isEmpty()) {
                    cnURI = currCnURI;
                    if(servLat != 0 && servLon != 0) 
                    minDist = distance(cnLat, servLat, cnLon, servLon, 0, 0 );
                } 
                else {
                    double currDist = 0;
                    if(servLat != 0 && servLon != 0) 
                        currDist = distance(cnLat, servLat, cnLon, servLon, 0, 0 );
                    if(currDist < minDist) {
                        minDist = currDist;
                        cnURI = currCnURI;
                    }
                    
                }
            }
        }
        
        String road = new String();
        String entry = new String();
        
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));

        Repository km4cRepo;
        
        if(pVirtuosoGraph4OSM.isEmpty()) {
            km4cRepo = new VirtuosoRepository("jdbc:virtuoso://".
        concat(pVirtuosoHost4OSM).
        concat(pVirtuosoPort4OSM),pVirtuosoUsername4OSM,pVirtuosoPassword4OSM);
        }
        else
        {
            km4cRepo = new VirtuosoRepository("jdbc:virtuoso://".
        concat(pVirtuosoHost4OSM).
        concat(pVirtuosoPort4OSM),pVirtuosoUsername4OSM,pVirtuosoPassword4OSM, 
                pVirtuosoGraph4OSM);
        }
                
        try ( RepositoryConnection km4cRepoConn = km4cRepo.getConnection() ) { 
            
            String reconSparql = "select distinct ?road ?entry { graph ?g { " +
                "<" + cnURI + "> a km4c:StreetNumber; " +
                "km4c:belongToRoad ?road; " +
                "km4c:hasExternalAccess ?entry " +
                "} }";
            
            TupleQuery reconQuery = km4cRepoConn.
                    prepareTupleQuery(QueryLanguage.SPARQL, reconSparql);
            
            try ( TupleQueryResult result = reconQuery.evaluate() ) {

                while (result.hasNext()) {
                    
                    BindingSet bindingSet = result.next();

                    road = bindingSet.getValue("road").stringValue();
                    entry = bindingSet.getValue("entry").stringValue();
                    
                }
                
                result.close();
                
            }
            
            km4cRepoConn.close();
            
        }
        
        km4cRepo.shutDown();
        
        if(!(road.isEmpty() || entry.isEmpty())) {
            return new ReconciliationResult(road, entry);
        }
        else
        {
            return null;
        }
        
    }
    
  /**
 * Calculate distance between two points in latitude and longitude taking
 * into account height difference. If you are not interested in height
 * difference pass 0.0. Uses Haversine method as its base.
 * 
 * lat1, lon1 Start point lat2, lon2 End point el1 Start altitude in meters
 * el2 End altitude in meters
     * @param lat1
     * @param lat2
     * @param lon1
     * @param lon2
     * @param el1
     * @param el2
     * @return 
 * @returns Distance in Meters
 */
public static double distance(double lat1, double lat2, double lon1,
        double lon2, double el1, double el2) {

    final int R = 6371; // Radius of the earth

    double latDistance = Math.toRadians(lat2 - lat1);
    double lonDistance = Math.toRadians(lon2 - lon1);
    double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
            + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
            * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    double distance = R * c * 1000; // convert to meters

    double height = el1 - el2;

    distance = Math.pow(distance, 2) + Math.pow(height, 2);

    return Math.sqrt(distance);
    }
    
    private static void setLogLevel() {
        
        Level logLevel;
                
        switch(pLog) {
            case "off":
                logLevel = Level.OFF;
                break;
            case "minimal":
                logLevel = Level.INFO;
                break;
            case "verbose":
                logLevel = Level.FINE;
                break;
            default:
                logLevel = Level.INFO;
        }

        LOGGER.setLevel(logLevel);
        ConsoleHandler handler = new ConsoleHandler();
        handler.setLevel(logLevel);
        LOGGER.addHandler(handler);
        
    }
    
}
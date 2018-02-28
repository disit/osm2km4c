
package rthousenum;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.math.BigInteger;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author disit
 */
public class Rthousenum {

    private static String pMysqlHostname;
    private static String pMysqlPort;
    private static String pMysqlDatabase;
    private static String pMysqlUsername;
    private static String pMysqlPassword;
    private static String pPostgresHostname;
    private static String pPostgresPort;
    private static String pPostgresDatabase;
    private static String pPostgresUsername;
    private static String pPostgresPassword;
    private static String pServEndpoint;
    private static String pIdle;
    private static String pOutput;
    private static String pLog;
    private static String pMysqlQuery;
    
    private static FileWriter fw;
    private static BufferedWriter bw;
    private static PrintWriter out;
    private static final Logger LOGGER =
      Logger.getLogger(Rthousenum.class.getName());
    
    /**
     * @param args the command line arguments
     * @throws java.lang.Exception
     */
    public static void main(String[] args) throws Exception {
        
        readArgs(args);
        
        setLogLevel();
        
        LOGGER.log(Level.INFO, "OSC file generation started.");
        
        fw = new FileWriter(pOutput, true);
        bw = new BufferedWriter(fw);
        out = new PrintWriter(bw);
        
        out.println("<osmChange version=\"0.6\" generator=\"disit\">");
        
        addNewNodes();

        out.println("</osmChange>");
        
        out.close();
        bw.close();
        fw.close();

        LOGGER.log(Level.INFO, "OSC file generation completed.");
        
    }
    
    private static void addNewNodes() throws Exception {
        
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        
        // String connectionString="jdbc:mysql://192.168.0.20:3306/SiiMobility?
        // user=SiiMobility&password=Mob7_1lity";
        String connString="jdbc:mysql://"+pMysqlHostname+pMysqlPort+"/"+
                pMysqlDatabase+"?user="+pMysqlUsername +
                "&password="+pMysqlPassword;
        
        Class.forName("com.mysql.jdbc.Driver");
        
        String changeset = getChangeset().toString();
        
        BigInteger baseId = getBaseId();
        BigInteger idDecrement = BigInteger.valueOf(1);
        
        try ( 
            Connection connection = DriverManager.getConnection(connString);
            Statement stm = connection.createStatement();
            /* select tbl_num_civico.EXT_NUM civico, 
            t.EXT_NAME toponimo, 
            tbl_accesso.x, tbl_accesso.y 
            from tbl_num_civico 
            join tbl_accesso on tbl_num_civico.COD_ACC_ES = tbl_accesso.COD_ACC 
            join tbl_toponimo_TER t on tbl_num_civico.COD_TOP = t.COD_TOP */
            ResultSet rs = stm.executeQuery(pMysqlQuery);
        ) {
            
            LOGGER.log(Level.FINE, pMysqlQuery);

            while (rs.next()) {

                String civico = rs.getString("civico");
                String toponimo_rt = rs.getString("toponimo");
                String lon = rs.getString("x");
                String lat = rs.getString("y");
                String osmidMunicipality = askForId(lat, lon, "municipality");
                String osmidWay = askForId(lat, lon, "way");
                String nearestNode = askForId(lat, lon, "node");
                
                String municip = askForName(osmidMunicipality, 
                        "municipality");
                String road = askForName(osmidWay, "way");
                String id = baseId.subtract(idDecrement).
                        toString();
                idDecrement = idDecrement.add(BigInteger.valueOf(1));
                String create = "<create>"
                    + "<node "
                    + "id=\""+id+"\" "
                    + "changeset=\""+changeset+"\" "
                    + "version=\"1\" "
                    + "lat=\""+lat+"\" "
                    + "lon=\""+lon+"\" "
                    + "timestamp=\""
                    + LocalDateTime.now().format(DateTimeFormatter.
                            ofPattern("yyyy-MM-dd HH:mm:ss"))
                    +"\">"
                    + "<tag k=\"addr:housenumber\" v=\""+civico+"\"/>"
                    + "<tag k=\"addr:street\" v=\""+road+";"+toponimo_rt+"\"/>" 
                    + "<tag k=\"addr:city\" v=\""+municip+"\"/>"      
                    + "<tag k=\"source\" v=\"Regione Toscana\"/>"   
                    + "<tag k=\"ref\" v=\""+nearestNode+"\"/>"   
                    + "</node>"
                    + "</create>";
                out.println(create);
                LOGGER.log(Level.FINE, create);

            }
        }
        
    }
    
     private static String askForId
        (String lat, String lon, String type) 
        throws Exception {
            
        LOGGER.log(Level.FINE, "Asking for ".concat(type).concat(" OSM ID"));
        
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
            
        String urlStr = pServEndpoint + 
            "lat=" + URLEncoder.encode(lat,"UTF-8") + 
            "&lon=" +URLEncoder.encode(lon,"UTF-8") +
            "&type="+URLEncoder.encode(type,"UTF-8");
        
        LOGGER.log(Level.FINE, urlStr);
        
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

        LOGGER.log(Level.FINE, "Response: ".concat(response));
        return response;
            
    }
        
    private static String askForName(String id, String what) throws Exception {

        LOGGER.log(Level.FINE, "Asking for ".concat(what).concat(" name"));
        
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        
        String query = new String();
        if("municipality".equals(what)) {
            query = "select v descr from relation_tags "
                    + "where relation_id = "+id+" and k = 'name'";
        }
        if("way".equals(what)) {
            query = "select coalesce(way_tags.v,relation_tags.v,'') descr from ways "
                    + "left join way_tags on way_tags.way_id = ways.id and k = 'name' "
                    + "left join relation_members on relation_members.member_id = ways.id "
                    + "left join relation_tags on relation_tags.relation_id = relation_members.relation_id and relation_tags.k = 'name' "
                    + "where ways.id = "+id;
        }
        if(query.isEmpty()) throw new Exception("Invalid argument: what");

        LOGGER.log(Level.FINE, query);
        
        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword;

        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc);
             java.sql.Statement st = pgresConn.createStatement();
             ResultSet rs = 
                st.executeQuery(query);   
        ) { 

            if(rs.next()) {
                LOGGER.log(Level.FINE, "Response: ".
                        concat(rs.getString("descr")));
                return rs.getString("descr");
            }
            else  {
                LOGGER.log(Level.FINE, "Not found");
                return null;
            }
        } 
    }
    
    private static BigInteger getBaseId() throws Exception {
        
        LOGGER.log(Level.FINE, "Asking for base ID for new nodes");
        
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        
        String query = "select coalesce(min(id),0) id from ( select id "
                + "from relations union select id from ways union select id "
                + "from nodes ) everything where id < 0";
        
        LOGGER.log(Level.FINE, query);

        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword;

        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc);
             java.sql.Statement st = pgresConn.createStatement();
             ResultSet rs = 
                st.executeQuery(query);   
        ) { 

            if(rs.next()) {
                
                BigInteger response = new BigInteger(rs.getString("id"));
                
                LOGGER.log(Level.FINE, "Response: ".
                        concat(response.toString()));
                        
                return response; 
            }
            else
                throw new Exception("Not found");

        } 
        
    }
    
    private static BigInteger getChangeset() throws Exception {
        
        LOGGER.log(Level.FINE, "Asking for changeset id");
        
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        
        String query = "select coalesce(min(changeset_id),0) changeset_id "
                + "from ( select "
                + "changeset_id from relations union select changeset_id from "
                + "ways union select changeset_id from nodes ) everything "
                + "where changeset_id < 0";

        LOGGER.log(Level.FINE, query);
        
        String jdbc = "jdbc:postgresql://" +
                pPostgresHostname + pPostgresPort + "/" +
                pPostgresDatabase + "?" +
                "user=" + pPostgresUsername + "&" +
                "password=" + pPostgresPassword;

        Class.forName("org.postgresql.Driver");
        try (Connection pgresConn = DriverManager.getConnection(jdbc);
             java.sql.Statement st = pgresConn.createStatement();
             ResultSet rs = 
                st.executeQuery(query);   
        ) { 

            if(rs.next()) {
                BigInteger response = new BigInteger(
                    rs.getString("changeset_id"))
                    .subtract(BigInteger.valueOf(1));
                LOGGER.log(Level.FINE, "Response: ".
                    concat(response.toString()));
                return response; 
            }
            else
                throw new Exception("Not found");

        } 

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
                    
                    case "-mh":
                    case "--mysql-host":
                        pMysqlHostname = arg;
                        break;
                    case "-mp":
                    case "--mysql-port":
                        pMysqlPort = arg;
                        break;
                    case "-md":
                    case "--mysql-dbname":
                        pMysqlDatabase = arg;
                        break;
                    case "-mu":
                    case "--mysql-user":
                        pMysqlUsername = arg;
                        break;
                    case "-mP":
                    case "--mysql-pass":
                        pMysqlPassword = arg;
                        break;
                    case "-mq":
                    case "--mysql-query":
                        pMysqlQuery = arg;
                        break;
                    case "-ph":
                    case "--pgres-host":
                        pPostgresHostname = arg;
                        break;
                    case "-pp":
                    case "--pgres-port":
                        pPostgresPort = arg;
                        break;
                    case "-pd":
                    case "--pgres-dbname":
                        pPostgresDatabase = arg;
                        break;
                    case "-pu":
                    case "--pgres-user":
                        pPostgresUsername = arg;
                        break;
                    case "-pP":
                    case "--pgres-pass":
                        pPostgresPassword = arg;
                        break;
                    case "-s":
                    case "--latlon2osnode":
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
                        throw new Exception("Unknown argument: "+currPar+ ". "+
                            "Launch without arguments for usage guide.");
                }
                currPar = new String();
            }
        }
        
        if(pPostgresHostname.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Postgres hostname. " +
                "Launch without arguments for usage guide."); 
        }
        if( ! ( pPostgresPort.isEmpty() || isNumeric(pPostgresPort) ) ) { 
            throw new Exception("Invalid argument: Postgres port. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(!pPostgresPort.isEmpty()) pPostgresPort = ":".
                concat(pPostgresPort);
        
        if(pPostgresDatabase.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Postgres database. " + 
                    "Launch without arguments for usage guide."); 
        }
                
        if(pPostgresUsername.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Postgres username. " + 
                    "Launch without arguments for usage guide."); 
        }
        
        if(pPostgresPassword.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Postgres password. " + 
                    "Launch without arguments for usage guide."); 
        }

        if(pMysqlHostname.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Mysql hostname. " +
                "Launch without arguments for usage guide."); 
        }
        if( ! ( pMysqlPort.isEmpty() || isNumeric(pMysqlPort) ) ) { 
            throw new Exception("Invalid argument: Mysql port. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(!pMysqlPort.isEmpty()) pMysqlPort = ":".
                concat(pMysqlPort);
        
        if(pMysqlDatabase.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Mysql database. " + 
                    "Launch without arguments for usage guide."); 
        }
                
        if(pMysqlUsername.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Mysql username. " + 
                    "Launch without arguments for usage guide."); 
        }
        
        if(pMysqlPassword.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Mysql password. " + 
                    "Launch without arguments for usage guide."); 
        }

        if(pMysqlQuery.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Mysql query. " + 
                    "Launch without arguments for usage guide."); 
        }
                
        if(pServEndpoint.isEmpty()) { 
            throw new Exception(
                    "Missing argument: latlon2osnode endpoint. " + 
                    "Launch without arguments for usage guide."); 
        }
        
        if(pOutput.isEmpty()) {
            throw new Exception(
                "Missing argument: output file. " + 
                "Launch without arguments for usage guide."); 
        }

        if((!pLog.isEmpty()) &&
            !(
                "off".equals(pLog) || 
                "minimal".equals(pLog) || 
                "verbose".equals(pLog)
            )) {
                throw new Exception("Invalid argument: Log level. " + 
                    "Launch without arguments for usage guide."); 
        }
                
        if((!pIdle.isEmpty()) && (!isNumeric(pIdle))) {
            throw new Exception("Invalid argument: Idle time. " + 
                    "Launch without arguments for usage guide."); 
        }

    }
    
    private static void usageGuide() {
        
        System.out.println(
            "RTHOUSENUM USAGE GUIDE                                        \n" +
            "--------------------------------------------------------------\n" +
            "This command generates an osmosis change file ready to be     \n" +
            "loaded for importing in our own version of the Open Street    \n" +                    
            "Map all the information about the civic numbers available in  \n" +          
            "the files provided by Regione Toscana.                        \n" +        
            "                                                              \n" +
            "List of arguments:                                            \n" +
            "-ph, --pgres-host: hostname of the server where Postgres is   \n" +
            "    running                                                   \n" +
            "-pp, --pgres-port: port on which the Postgres server instance \n" +
            "     is listening                                             \n" +
            "-pd, --pgres-dbname: name of the Postgres database where OSM  \n" +
            "    data is housed                                            \n" +
            "-pu, --pgres-user: username for logging into Postgres         \n" +
            "-pP, --pgres-pass: password for logging into Postgres         \n" +
            "-mh, --mysql-host: hostname of the server where the MySql     \n" +
            "    database containing the Regione Toscana data is housed    \n" +
            "-mp, --mysql-port: port on which Mysql server is listening    \n" +
            "-md, --mysql-dbname: name of the Mysql database where the     \n" +
            "    Regione Toscana data is contained                         \n" +
            "-mu, --mysql-user: username for logging into Mysql            \n" +
            "-mP, --mysql-pass: password for logging into Mysql            \n" +
            "-mq, --mysql-query: the query executed on MySql for retrieving\n" +
            "    the data provided by Regione Toscana. The target list     \n" +
            "    MUST formed by four fields: civico, toponimo, x, y. The   \n" +
            "    four fields respectively MUST contain the civic number,   \n" +
            "    the street name, and the geospatial coordinates.          \n" +
            "-s, --latlon2osnode: URL of the latlon2osnode endpoint        \n" +
            "-o, --output: the path to the output file (an osmosis change  \n" +                    
            "    file)                                                     \n" +
            "-l, --log: optional log level, allowed valorizations are:     \n" +                    
            "    off, minimal, verbose. Defaults to minimal.               \n" +
            "-i, --idle: optional idle time before each connection to      \n" +                    
            "    external data sources (both via JDBC or HTTP requests)    \n"       
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
        
        LOGGER.log(Level.INFO, "Log level set to ".concat(logLevel.getName()));
        
    }
    
}

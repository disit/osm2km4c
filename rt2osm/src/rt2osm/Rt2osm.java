package rt2osm;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.eclipse.rdf4j.model.IRI;
import org.eclipse.rdf4j.model.Literal;
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
import virtuoso.rdf4j.driver.VirtuosoRepository;

/**
 *
 * @author disit
 */
public class Rt2osm {

    private static String pVirtuosoHost = new String();
    private static String pVirtuosoPort = new String();
    private static String pVirtuosoUsername = new String();
    private static String pVirtuosoPassword = new String();
    private static String pVirtuosoRTGraph = new String();
    private static String pVirtuosoOSMGraph = new String();
    private static String pVirtuosoTargetGraph = new String();
    private static String pWhat = new String();
    private static String pOutput = new String();
    private static String pLog = new String();
    private static String pIdle = new String();
    private static String pMunicipalityName = new String();
    private static final Logger LOGGER =
        Logger.getLogger(Rt2osm.class.getName());
    private static final ModelBuilder RDF_BUILDER = new ModelBuilder();
    
    /**
     * @param args the command line arguments
     * @throws java.lang.Exception
     */
    public static void main(String[] args) throws Exception {
        
        readArgs(args);
        
        setLogLevel();
                
        LOGGER.log(Level.INFO, "Reconciliation started.");
        
        RDF_BUILDER.setNamespace("km4c","http://www.disit.org/km4city/schema#");
        RDF_BUILDER.setNamespace("owl","http://www.w3.org/2002/07/owl#");
        RDF_BUILDER.setNamespace("rdf","http://www.w3.org/1999/02/22-rdf-syntax-ns#");
        RDF_BUILDER.setNamespace("dct","http://purl.org/dc/terms/");
        RDF_BUILDER.setNamespace("geo","http://www.w3.org/2003/01/geo/wgs84_pos#");
        
        Repository repos = new VirtuosoRepository("jdbc:virtuoso://".
                concat(pVirtuosoHost).
                concat(pVirtuosoPort),pVirtuosoUsername,
                pVirtuosoPassword, pVirtuosoTargetGraph);
        
        ((VirtuosoRepository)repos).setQueryTimeout(1800);
        
        repos.initialize();
        
        try ( RepositoryConnection reposConn = repos.getConnection() ) {

            reposConn.setNamespace("km4c", "http://www.disit.org/km4city/schema#");
            reposConn.setNamespace("owl", "http://www.w3.org/2002/07/owl#");
            reposConn.setNamespace("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#");
            reposConn.setNamespace("dct", "http://purl.org/dc/terms/");
            reposConn.setNamespace("geo", "http://www.w3.org/2003/01/geo/wgs84_pos#");
            
            if("counties".equals(pWhat)) {
                reconciliateCounties(reposConn);
            }
            
            if("municipalities".equals(pWhat)) {
                reconciliateMunicipalities(reposConn);
            }
                
            if("optimize-rt".equals(pWhat)) {
                optimizeGraph(reposConn, pVirtuosoRTGraph);
            }
            
            if("optimize-osm".equals(pWhat)) {
                optimizeGraph(reposConn, pVirtuosoOSMGraph);
            }
            
            if("roads-seed".equals(pWhat)) {
                reconciliateRoadsSeed(reposConn);
            }
            
            if("roads-step".equals(pWhat)) {
                reconciliateRoadsStep(reposConn);
            }
            
            if("elements-step1".equals(pWhat)) {
                reconciliateElementsStep1(reposConn);
            }    
            
            if("elements-step2".equals(pWhat)) {
                reconciliateElementsStep2(reposConn);
            }   
                        
        }
        
        Model rdfModel = RDF_BUILDER.build();
            
        persistModel(rdfModel);
        
    }
    
    private static void reconciliateRoadsSeed(RepositoryConnection reposConn) {
        
        String query = "select ?tr ?r " + 
            "  from named <"+pVirtuosoRTGraph+"> "+
            "  from named <"+pVirtuosoOSMGraph+"> { " +
            "  graph <"+pVirtuosoRTGraph+"> { " +
            "    ?tr km4c:extendName ?tn ; " +
            "    km4c:inMunicipalityOf ?tm . " +
            "    ?tm dct:alternative ?tma. " +
            "  } " +
            "  graph <"+pVirtuosoOSMGraph+"> { " +
            "    ?r km4c:extendName ?n ; " +
            "    km4c:inMunicipalityOf ?m . " +
            "    ?m dct:alternative ?tma. " +
            "  } " +
            "  FILTER ( lcase(?tn) = lcase(?n) ) " +
            "}";

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        query );
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                BindingSet bindingSet = result.next();

                Value tr = bindingSet.getValue("tr");
                Value r = bindingSet.getValue("r");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI trIRI = vFactory.createIRI(tr.stringValue());
                IRI rIRI = vFactory.createIRI(r.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(tr.stringValue()).
                        add("owl:sameAs", rIRI);

                RDF_BUILDER.defaultGraph().
                        subject(r.stringValue()).
                        add("owl:sameAs", trIRI);
            }

        }
        
    }
    
    private static void reconciliateElementsStep1(RepositoryConnection reposConn) {
    
        String elementsQuery1 = "SELECT ?deo ?det " +
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> " + 
            " from named <"+pVirtuosoTargetGraph+"> { " +    
            "  { " +
            "    select (?et as ?det) (?eo as ?deo) ?dist where { " +
            "      graph <"+pVirtuosoRTGraph+"> { " +
            "        ?rt km4c:containsElement ?et . " +
            "        ?et km4c:startsAtNode ?est ; " +
            "          km4c:endsAtNode ?eet . " +
            "        ?est geo:geometry ?esgt . " +
            "        ?eet geo:geometry ?eegt . " +
            "      } " +
            "      graph <"+pVirtuosoOSMGraph+"> { " +
            "        ?ro km4c:containsElement ?eo . " +
            "        ?eo km4c:startsAtNode ?eso ; " +
            "          km4c:endsAtNode ?eeo . " +
            "        ?eso geo:geometry ?esgo . " +
            "        ?eeo geo:geometry ?eego . " +
            "      } " +
            "      graph <"+pVirtuosoTargetGraph+"> { " +
            "        ?rt owl:sameAs ?ro " +
            "      } " +
            "      bind(bif:st_distance(?esgt, ?esgo)+bif:st_distance(?eegt,?eego) as ?dist) . " +
            "    } " +
            "  } " +
            "  { " +
            "    select ( ?et as ?get ) ( min(?dist) as ?mindist ) where { " +
            "      graph <"+pVirtuosoRTGraph+"> { " +
            "        ?rt km4c:containsElement ?et . " +
            "        ?et km4c:startsAtNode ?est ; " +
            "          km4c:endsAtNode ?eet . " +
            "        ?est geo:geometry ?esgt . " +
            "        ?eet geo:geometry ?eegt . " +
            "      } " +
            "      graph <"+pVirtuosoOSMGraph+"> { " +
            "        ?ro km4c:containsElement ?eo . " +
            "        ?eo km4c:startsAtNode ?eso ; " +
            "          km4c:endsAtNode ?eeo . " +
            "        ?eso geo:geometry ?esgo . " +
            "        ?eeo geo:geometry ?eego . " +
            "      } " +
            "      graph <"+pVirtuosoTargetGraph+"> { " +
            "        ?rt owl:sameAs ?ro " +
            "      } " +
            "      bind(bif:st_distance(?esgt, ?esgo)+bif:st_distance(?eegt,?eego) as ?dist) . " +
            "    } " +
            "    group by ?et " +
            "  } " +
            "  filter(?get = ?det && ?dist = ?mindist) " +
            "}";

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        elementsQuery1 );
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("deo");
                Value tr2 = bindingSet.getValue("det");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }

    }
    
    private static void reconciliateElementsStep2(RepositoryConnection reposConn) {
    
        String elementsQuery1 = "SELECT ?deo ?det " +
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> " + 
            " from named <"+pVirtuosoTargetGraph+"> { " +    
            "  { " +
            "    select (?et as ?det) (?eo as ?deo) ?dist where { " +
            "      graph <"+pVirtuosoRTGraph+"> { " +
            "        ?rt km4c:containsElement ?et . " +
            "        ?et km4c:startsAtNode ?est ; " +
            "          km4c:endsAtNode ?eet . " +
            "        ?est geo:geometry ?esgt . " +
            "        ?eet geo:geometry ?eegt . " +
            "      } " +
            "      graph <"+pVirtuosoOSMGraph+"> { " +
            "        ?ro km4c:containsElement ?eo . " +
            "        ?eo km4c:startsAtNode ?eso ; " +
            "          km4c:endsAtNode ?eeo . " +
            "        ?eso geo:geometry ?esgo . " +
            "        ?eeo geo:geometry ?eego . " +
            "      } " +
            "      graph <"+pVirtuosoTargetGraph+"> { " +
            "        ?rt owl:sameAs ?ro " +
            "      } " +
            "      bind(bif:st_distance(?esgt, ?esgo)+bif:st_distance(?eegt,?eego) as ?dist) . " +
            "    } " +
            "  } " +
            "  { " +
            "    select ( ?eo as ?got ) ( min(?dist) as ?mindist ) where { " +
            "      graph <"+pVirtuosoRTGraph+"> { " +
            "        ?rt km4c:containsElement ?et . " +
            "        ?et km4c:startsAtNode ?est ; " +
            "          km4c:endsAtNode ?eet . " +
            "        ?est geo:geometry ?esgt . " +
            "        ?eet geo:geometry ?eegt . " +
            "      } " +
            "      graph <"+pVirtuosoOSMGraph+"> { " +
            "        ?ro km4c:containsElement ?eo . " +
            "        ?eo km4c:startsAtNode ?eso ; " +
            "          km4c:endsAtNode ?eeo . " +
            "        ?eso geo:geometry ?esgo . " +
            "        ?eeo geo:geometry ?eego . " +
            "      } " +
            "      graph <"+pVirtuosoTargetGraph+"> { " +
            "        ?rt owl:sameAs ?ro " +
            "      } " +
            "      filter not exists { " +
            "        graph <"+pVirtuosoTargetGraph+"> { " +
            "          ?eo owl:sameAs ?something " +
            "        } " +
            "      } " +
            "      bind(bif:st_distance(?esgt, ?esgo)+bif:st_distance(?eegt,?eego) as ?dist) . " +
            "    } " +
            "    group by ?eo " +
            "  } " +
            "  filter(?got = ?deo && ?dist = ?mindist) " +
            "}";

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        elementsQuery1 );
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("deo");
                Value tr2 = bindingSet.getValue("det");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

            }

        }

    }
    
    private static void reconciliateRoadsStep(RepositoryConnection reposConn) 
            throws Exception {
        
        String baseRoadsSparql = "select ?r2 ?tr2 " +
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> " + 
            " from named <"+pVirtuosoTargetGraph+"> { " +    
            " graph <"+pVirtuosoTargetGraph+"> { " +
            "    ?r owl:sameAs ?tr . " +
            "    ?tr owl:sameAs ?r . " +
            "  } " +
            "  filter not exists { "+
            "    graph <"+pVirtuosoTargetGraph+"> { ?r2 owl:sameAs ?something } " +
            "  } " +
            "  filter not exists { " +
            "    graph <"+pVirtuosoTargetGraph+"> { ?tr2 owl:sameAs ?somethingelse } " + 
            "  } " +
            "  graph <"+pVirtuosoRTGraph+"> { " +
            "    { " +
            "      ?te1 km4c:startsAtNode ?tn . " +
            "      ?te2 km4c:startsAtNode ?tn . " +
            "      ?tr km4c:containsElement ?te1 . " +
            "      ?tr2 km4c:containsElement ?te2 . " +
            "      ?tr km4c:extendName ?ten . " +
            "      ?tr2 km4c:extendName ?ten2 . " +
            "      ?tr2 km4c:roadName ?trn2 . " +
            "      filter ( ?ten != ?ten2 ) . " +
            "    } " +
            "    UNION" +
            "    {" +
            "      ?te1 km4c:startsAtNode ?tn. " +
            "      ?te2 km4c:endsAtNode ?tn. " +
            "      ?tr km4c:containsElement ?te1 . " +
            "      ?tr2 km4c:containsElement ?te2 . " +
            "      ?tr km4c:extendName ?ten . " +
            "      ?tr2 km4c:extendName ?ten2 . " +
            "      ?tr2 km4c:roadName ?trn2 . " +
            "      filter ( ?ten != ?ten2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?te1 km4c:endsAtNode ?tn. " +
            "      ?te2 km4c:startsAtNode ?tn. " +
            "      ?tr km4c:containsElement ?te1 . " +
            "      ?tr2 km4c:containsElement ?te2 . " +
            "      ?tr km4c:extendName ?ten . " +
            "      ?tr2 km4c:extendName ?ten2 . " +
            "      ?tr2 km4c:roadName ?trn2 . " +
            "      filter ( ?ten != ?ten2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?te1 km4c:endsAtNode ?tn. " +
            "      ?te2 km4c:endsAtNode ?tn. " +
            "      ?tr km4c:containsElement ?te1 . " +
            "      ?tr2 km4c:containsElement ?te2 . " +
            "      ?tr km4c:extendName ?ten . " +
            "      ?tr2 km4c:extendName ?ten2 . " +
            "      ?tr2 km4c:roadName ?trn2 . " +
            "      filter ( ?ten != ?ten2 ) . " +
            "    } " +
            "  } " +
            "  graph <"+pVirtuosoOSMGraph+"> { " +
            "    { " +
            "      ?e1 km4c:startsAtNode ?n . " +
            "      ?e2 km4c:startsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?en != ?en2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:startsAtNode ?n . " +
            "      ?e2 km4c:endsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?en != ?en2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:endsAtNode ?n . " +
            "      ?e2 km4c:startsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?en != ?en2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:endsAtNode ?n . " +
            "      ?e2 km4c:endsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?en != ?en2 ) . " +
            "    } " +
            "  } " ;
        
        if(reconciliateRoads1stAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads2ndAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads3rdAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads4thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads5thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads6thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads7thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads8thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads9thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads10thAttmpt(reposConn)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads11thAttmpt(reposConn)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads12thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads13thAttmpt(reposConn, baseRoadsSparql)) return;
        if(!pIdle.isEmpty()) Thread.sleep(Integer.parseInt(pIdle));
        if(reconciliateRoads14thAttmpt(reposConn)) return;
        System.exit(1);
        
    }
    
    private static boolean reconciliateRoads1stAttmpt(
            RepositoryConnection reposConn, String baseQuery) {
        
        String constraint = "filter(regex(?ten2,concat(?en2,\"$\"),\"i\") || regex(?en2,concat(?ten2,\"$\"),\"i\"))";
        
        boolean wasGeneratedSomething = false;
        
        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, 
                    baseQuery + constraint + " } " );
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) { 
                
                wasGeneratedSomething = true;
                
                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(r2.stringValue()).
                    add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                    subject(tr2.stringValue()).
                    add("owl:sameAs", r2IRI);
            }
            
        }
        catch(Exception e) {
            return false;
        }
        
        return wasGeneratedSomething;
        
    }
    
    private static boolean reconciliateRoads2ndAttmpt(
            RepositoryConnection reposConn, String baseQuery) {
        
        String constraint = "filter(regex(?ten2,concat(\"^\",?en2),\"i\") || regex(?en2,concat(\"^\",?ten2),\"i\"))";
        
        boolean wasGeneratedSomething = false;
        
        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, 
                    baseQuery + constraint + " } " );
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) { 
                
                wasGeneratedSomething = true;
                
                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(r2.stringValue()).
                    add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                    subject(tr2.stringValue()).
                    add("owl:sameAs", r2IRI);
            }
            
        }
        catch(Exception e) {
            return false;
        }
        
        return wasGeneratedSomething;
        
    }
    
    private static boolean reconciliateRoads3rdAttmpt(
            RepositoryConnection reposConn, String baseQuery) {
        
        String constraint = "filter(regex(?ten2, ?en2, \"i\") || regex(?en2, ?ten2, \"i\" ))";
        
        boolean wasGeneratedSomething = false;
        
        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, 
                    baseQuery + constraint + " } " );
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) { 
                
                wasGeneratedSomething = true;
                
                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(r2.stringValue()).
                    add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                    subject(tr2.stringValue()).
                    add("owl:sameAs", r2IRI);
            }
            
        }
        catch(Exception e) {
            return false;
        }
        
        return wasGeneratedSomething;
        
    }
    
    private static boolean reconciliateRoads4thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {
        
        String constraint = "filter(?trn2 = ?rn2)";
        
        boolean wasGeneratedSomething = false;
        
        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, 
                    baseQuery + constraint + " } " );
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) { 
                
                wasGeneratedSomething = true;
                
                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(r2.stringValue()).
                    add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                    subject(tr2.stringValue()).
                    add("owl:sameAs", r2IRI);
            }
            
        }
        catch(Exception e) {
            return false;
        }
        
        return wasGeneratedSomething;
        
    }
    
    private static boolean reconciliateRoads5thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {
        
        String constraint = "filter(regex(?trn2,concat(?rn2,\"$\"),\"i\") || regex(?rn2,concat(?trn2,\"$\"),\"i\"))";
        
        boolean wasGeneratedSomething = false;
        
        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, 
                    baseQuery + constraint + " } " );
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) { 
                
                wasGeneratedSomething = true;
                
                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(r2.stringValue()).
                    add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                    subject(tr2.stringValue()).
                    add("owl:sameAs", r2IRI);
            }
            
        }
        catch(Exception e) {
            return false;
        }
        
        return wasGeneratedSomething;
        
    }
    
    private static boolean reconciliateRoads6thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {
        
        String constraint = "filter(regex(?trn2,concat(\"^\",?rn2),\"i\") || regex(?rn2,concat(\"^\",?trn2),\"i\"))";
        
        boolean wasGeneratedSomething = false;
        
        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, 
                    baseQuery + constraint + " } " );
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) { 
                
                wasGeneratedSomething = true;
                
                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(r2.stringValue()).
                    add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                    subject(tr2.stringValue()).
                    add("owl:sameAs", r2IRI);
            }
            
        }
        catch(Exception e) {
            return false;
        }
        
        return wasGeneratedSomething;
        
    }
    
    private static boolean reconciliateRoads7thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {
        
        String constraint = "filter(regex(?trn2, ?rn2, \"i\") || regex(?rn2, ?trn2, \"i\" ))";
        
        boolean wasGeneratedSomething = false;
        
        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, 
                    baseQuery + constraint + " } " );
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) { 
                
                wasGeneratedSomething = true;
                
                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(r2.stringValue()).
                    add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                    subject(tr2.stringValue()).
                    add("owl:sameAs", r2IRI);
            }
            
        }
        catch(Exception e) {
            return false;
        }
        
        return wasGeneratedSomething;
        
    }
    
    private static boolean reconciliateRoads8thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {

        String constraint = "filter( regex( str(?trn2), concat(\"\\\\b(\",replace(str(?rn2),\"^.*\\\\s\\\\b(?=.*$)\",\"\"),\")\\\\b\") , \"i\") )";

        boolean wasGeneratedSomething = false;

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        baseQuery + constraint + " } ");
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                wasGeneratedSomething = true;

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }
        catch(Exception e) {
            return false;
        }

        return wasGeneratedSomething;

    }
    
    private static boolean reconciliateRoads9thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {

        String constraint = "filter( regex( str(?rn2), concat(\"\\\\b(\",replace(str(?trn2),\"^.*\\\\s\\\\b(?=.*$)\",\"\"),\")\\\\b\") , \"i\") )";

        boolean wasGeneratedSomething = false;

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        baseQuery + constraint + " } ");
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                wasGeneratedSomething = true;

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }
        catch(Exception e) {
            return false;
        }

        return wasGeneratedSomething;

    }
    
    private static boolean reconciliateRoads10thAttmpt(
            RepositoryConnection reposConn) {

        String roadExtra1Query = "SELECT ?r2 ?tr " +
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> " + 
            " from named <"+pVirtuosoTargetGraph+"> { " +    
            "  graph <"+pVirtuosoOSMGraph+"> { " +
            "    { " +
            "      ?e1 km4c:startsAtNode ?n . " +
            "      ?e2 km4c:startsAtNode ?n. " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:startsAtNode ?n. " +
            "      ?e2 km4c:endsAtNode ?n. " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:endsAtNode ?n . " +
            "      ?e2 km4c:startsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:endsAtNode ?n . " +
            "      ?e2 km4c:endsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "  } " +
            "  graph <"+pVirtuosoOSMGraph+"> { " +
            "    ?r km4c:roadType ?rt . " +
            "    ?r2 km4c:roadType ?rt2 . " +
            "  } " +
            "  graph <"+pVirtuosoRTGraph+"> { " +
            "    ?tr a km4c:Road . " +
            "  }" +
            "  graph <"+pVirtuosoTargetGraph+"> { " +
            "    ?r owl:sameAs ?tr . " +
            "  } " +
            "  filter not exists { graph <"+pVirtuosoTargetGraph+"> { ?r2 owl:sameAs ?something } } " +
            "  filter( contains(?rt,?rt2) || contains(?rt2, ?rt) ) . " +
            "  filter( contains(?rn, ?rn2) || contains (?rn2, ?rn) ) . " +
            "}"; 
        
        boolean wasGeneratedSomething = false;

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        roadExtra1Query );
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                wasGeneratedSomething = true;

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }
        catch(Exception e) {
            return false;
        }

        return wasGeneratedSomething;

    }
    
    private static boolean reconciliateRoads11thAttmpt(
            RepositoryConnection reposConn) {

        String roadExtra2Query = "select ?r2 ?tr " +
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> " + 
            " from named <"+pVirtuosoTargetGraph+"> { " +    
            "  graph <"+pVirtuosoRTGraph+"> { " +
            "    { " +
            "      ?e1 km4c:startsAtNode ?n . " +
            "      ?e2 km4c:startsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:startsAtNode ?n . " +
            "      ?e2 km4c:endsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:endsAtNode ?n . " +
            "      ?e2 km4c:startsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "    UNION " +
            "    { " +
            "      ?e1 km4c:endsAtNode ?n . " +
            "      ?e2 km4c:endsAtNode ?n . " +
            "      ?r km4c:containsElement ?e1 . " +
            "      ?r2 km4c:containsElement ?e2 . " +
            "      ?r km4c:extendName ?en . " +
            "      ?r2 km4c:extendName ?en2 . " +
            "      ?r km4c:roadName ?rn . " +
            "      ?r2 km4c:roadName ?rn2 . " +
            "      filter ( ?r != ?r2 ) . " +
            "    } " +
            "  } " +
            "   GRAPH <"+pVirtuosoRTGraph+"> { " +
            "    ?r km4c:roadType ?rt . " +
            "    ?r2 km4c:roadType ?rt2 . " +
            "  } " +
            "  graph <"+pVirtuosoOSMGraph+"> { " +
            "    ?tr km4c:extendName ?trn . " +
            "  } " +
            "  graph <"+pVirtuosoTargetGraph+"> { " +
            "    ?r owl:sameAs ?tr . " +
            "  } " +
            "  filter not exists { graph <"+pVirtuosoTargetGraph+"> { ?r2 owl:sameAs ?something } } " +
            "  filter( contains(?rt,?rt2) || contains(?rt2, ?rt) ) . " +
            "  filter( contains(?rn, ?rn2) || contains (?rn2, ?rn) ) . " +
            "}"; 
        
        boolean wasGeneratedSomething = false;

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        roadExtra2Query );
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                wasGeneratedSomething = true;

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }
        catch(Exception e) {
            return false;
        }

        return wasGeneratedSomething;

    }
    
    private static boolean reconciliateRoads12thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {

        String constraint = "filter(regex(str(?trn2), replace(?rn2,\" \",\"\"), \"i\") )";

        boolean wasGeneratedSomething = false;

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        baseQuery + constraint + " } ");
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                wasGeneratedSomething = true;

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }
        catch(Exception e) {
            return false;
        }

        return wasGeneratedSomething;

    }
    
    private static boolean reconciliateRoads13thAttmpt(
            RepositoryConnection reposConn, String baseQuery) {

        String constraint = "filter(regex(str(?rn2), replace(?trn2,\" \",\"\"), \"i\") )";

        boolean wasGeneratedSomething = false;

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        baseQuery + constraint + " } ");
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                wasGeneratedSomething = true;

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr2");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }
        catch(Exception e) {
            return false;
        }

        return wasGeneratedSomething;

    }
    
    private static boolean reconciliateRoads14thAttmpt(
            RepositoryConnection reposConn) {

        String roadExtra3Query = "select ?r2 ?tr " +
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> " + 
            " from named <"+pVirtuosoTargetGraph+"> { " +    
            "  graph <"+pVirtuosoOSMGraph+"> { " +
            "    ?r km4c:extendName ?n . " +
            "    ?r2 km4c:extendName ?n . " +
            "    filter( ?r != ?r2 ) " +
            "  } " +
            "  graph <"+pVirtuosoTargetGraph+"> { " +
            "    ?r owl:sameAs ?tr . " +
            "  } " +
            "  graph <"+pVirtuosoRTGraph+"> { " +
            "    ?tr a km4c:Road . " +
            "  } " +
            "  filter not exists { graph <"+pVirtuosoTargetGraph+"> { ?r2 owl:sameAs ?something } } " +
            "}"; 
        
        boolean wasGeneratedSomething = false;

        TupleQuery targetQuery = reposConn.
                prepareTupleQuery(QueryLanguage.SPARQL,
                        roadExtra3Query );
        
        targetQuery.setMaxExecutionTime(1800);

        try (TupleQueryResult result = targetQuery.evaluate()) {

            while (result.hasNext()) {

                wasGeneratedSomething = true;

                BindingSet bindingSet = result.next();

                Value r2 = bindingSet.getValue("r2");
                Value tr2 = bindingSet.getValue("tr");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI r2IRI = vFactory.createIRI(r2.stringValue());
                IRI tr2IRI = vFactory.createIRI(tr2.stringValue());

                RDF_BUILDER.defaultGraph().
                        subject(r2.stringValue()).
                        add("owl:sameAs", tr2IRI);

                RDF_BUILDER.defaultGraph().
                        subject(tr2.stringValue()).
                        add("owl:sameAs", r2IRI);
            }

        }
        catch(Exception e) {
            return false;
        }

        return wasGeneratedSomething;

    }
    
    private static void optimizeGraph(RepositoryConnection reposConn, 
            String graph) {
        
        String optimizeSparql = 
            " select * from named <"+graph+"> { graph <"+graph+"> { " +
            "    ?s foaf:name \""+pMunicipalityName+"\" . " +
            "    ?r km4c:inMunicipalityOf ?s ; " +
            "    km4c:containsElement ?e ; " +
            "    km4c:extendName ?en ; " +
            "    km4c:roadName ?rn ; " +
            "    km4c:roadType ?rt . " +
            "    ?s dct:alternative ?sa . " +
            "    ?e km4c:startsAtNode ?esn ; " +
            "    km4c:endsAtNode ?een . " +
            "    ?esn geo:geometry ?esng . " +
            "    ?een geo:geometry ?eeng . " +
            "}}";

        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, optimizeSparql);
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) {

                BindingSet bindingSet = result.next();

                Value s = bindingSet.getValue("s");
                Value r = bindingSet.getValue("r");
                Value e = bindingSet.getValue("e");
                Value en = bindingSet.getValue("en");
                Value rn = bindingSet.getValue("rn");
                Value rt = bindingSet.getValue("rt");
                Value sa = bindingSet.getValue("sa");
                Value esn = bindingSet.getValue("esn");
                Value een = bindingSet.getValue("een");
                Value esng = bindingSet.getValue("esng");
                Value eeng = bindingSet.getValue("eeng");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI sIRI = vFactory.createIRI(s.stringValue());
                IRI eIRI = vFactory.createIRI(e.stringValue());
                Literal enLiteral = vFactory.createLiteral(en  != null ? en.stringValue() : "");
                Literal rnLiteral = vFactory.createLiteral(rn != null ? rn.stringValue() : "");
                Literal rtLiteral = vFactory.createLiteral(rt != null ? rt.stringValue() : "");
                Literal saLiteral = vFactory.createLiteral(sa != null ? sa.stringValue() : "");
                IRI esnIRI = vFactory.createIRI(esn.stringValue());
                IRI eenIRI = vFactory.createIRI(een.stringValue());
                IRI geom = vFactory.createIRI("http://www.openlinksw.com/schemas/virtrdf#Geometry");
                Literal esngLiteral = vFactory.createLiteral(esng.stringValue(),geom);
                Literal eengLiteral = vFactory.createLiteral(eeng.stringValue(),geom);
                
                RDF_BUILDER.defaultGraph().
                    subject(r.stringValue()).
                    add("rdf:type", "km4c:Road");

                RDF_BUILDER.defaultGraph().
                    subject(r.stringValue()).
                    add("km4c:inMunicipalityOf", sIRI);

                RDF_BUILDER.defaultGraph().
                    subject(r.stringValue()).
                    add("km4c:containsElement", eIRI);
                
                RDF_BUILDER.defaultGraph().
                    subject(r.stringValue()).
                    add("km4c:extendName", enLiteral);
                
                RDF_BUILDER.defaultGraph().
                    subject(r.stringValue()).
                    add("km4c:roadName", rnLiteral);
                                
                RDF_BUILDER.defaultGraph().
                    subject(r.stringValue()).
                    add("km4c:roadType", rtLiteral);

                RDF_BUILDER.defaultGraph().
                    subject(s.stringValue()).
                    add("dct:alternative", saLiteral);     
                
                RDF_BUILDER.defaultGraph().
                    subject(e.stringValue()).
                    add("rdf:type", "km4c:RoadElement");
                
                RDF_BUILDER.defaultGraph().
                    subject(e.stringValue()).
                    add("km4c:startsAtNode", esnIRI);

                RDF_BUILDER.defaultGraph().
                    subject(e.stringValue()).
                    add("km4c:endsAtNode", eenIRI);   
                
                RDF_BUILDER.defaultGraph().
                    subject(esn.stringValue()).
                    add("rdf:type", "km4c:Node");

                RDF_BUILDER.defaultGraph().
                    subject(esn.stringValue()).
                    add("geo:geometry", esngLiteral);
                
                RDF_BUILDER.defaultGraph().
                    subject(een.stringValue()).
                    add("rdf:type", "km4c:Node");
                
                RDF_BUILDER.defaultGraph().
                    subject(een.stringValue()).
                    add("geo:geometry", eengLiteral);      
                
            }
        }
    }
    
    private static void reconciliateCounties(RepositoryConnection reposConn) {
        
     

String provinceSparql = "select ?op ?tp " + 
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> { " +
            "graph <" + pVirtuosoRTGraph + "> { " +
            "   ?tp a km4c:Province ; " +
            "   dct:alternative ?ta . " +
            "} " +
            "graph <" + pVirtuosoOSMGraph + "> { " +
            "   ?op a km4c:Province ; " +
            "   dct:alternative ?ta . " +
            "} }";

        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, provinceSparql);
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) {

                BindingSet bindingSet = result.next();

                Value tp = bindingSet.getValue("tp");
                Value op = bindingSet.getValue("op");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI tpIRI = vFactory.createIRI(tp.stringValue());
                IRI opIRI = vFactory.createIRI(op.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(tp.stringValue()).
                    add("owl:sameAs", opIRI);

                RDF_BUILDER.defaultGraph().
                    subject(op.stringValue()).
                    add("owl:sameAs", tpIRI);

            }
        } 
        
    }
    
    private static void reconciliateMunicipalities(RepositoryConnection reposConn) {
        
        String municipalitiesSparql = "select ?tm ?om " +
            " from named <"+pVirtuosoRTGraph+"> " + 
            " from named <"+pVirtuosoOSMGraph+"> { " +
            "graph <" + pVirtuosoRTGraph + "> { " +
            "   ?tm a km4c:Municipality ; " +
            "   dct:alternative ?ta . " +
            "} " +
            "graph <" + pVirtuosoOSMGraph + "> { " +
            "   ?om a km4c:Municipality ; " +
            "   dct:alternative ?ta . " +
            "} }";

        TupleQuery targetQuery = reposConn.
            prepareTupleQuery(QueryLanguage.SPARQL, municipalitiesSparql);
        
        targetQuery.setMaxExecutionTime(1800);

        try ( TupleQueryResult result = targetQuery.evaluate() ) {

            while (result.hasNext()) {

                BindingSet bindingSet = result.next();

                Value tp = bindingSet.getValue("tm");
                Value op = bindingSet.getValue("om");

                ValueFactory vFactory = SimpleValueFactory.getInstance();
                IRI tpIRI = vFactory.createIRI(tp.stringValue());
                IRI opIRI = vFactory.createIRI(op.stringValue());

                RDF_BUILDER.defaultGraph().
                    subject(tp.stringValue()).
                    add("owl:sameAs", opIRI);

                RDF_BUILDER.defaultGraph().
                    subject(op.stringValue()).
                    add("owl:sameAs", tpIRI);

            }
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
                    case "-h":
                    case "--virt-host":
                        pVirtuosoHost = arg;
                        break;
                    case "-p":
                    case "--virt-port":
                        pVirtuosoPort = arg;
                        break;
                    case "-u":
                    case "--virt-user":
                        pVirtuosoUsername = arg;
                        break;
                    case "-P":
                    case "--virt-pwd":
                        pVirtuosoPassword = arg;
                        break;
                    case "-rg":
                    case "--virt-rt-graph":
                        pVirtuosoRTGraph = arg;
                        break;
                    case "-og":
                    case "--virt-os-graph":
                        pVirtuosoOSMGraph = arg;
                        break;
                    case "-tg":
                    case "--virt-target-graph":
                        pVirtuosoTargetGraph = arg;
                        break;
                    case "-w":
                    case "--what":
                        pWhat = arg;
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
                    case "-m":
                    case "--municipality":
                        pMunicipalityName = arg;
                        break;
                    default:
                        throw new Exception("Unknown argument: "+currPar+ ". "+
                            "Launch without arguments for usage guide.");
                }
                currPar = new String();
            }
        }
        
        if(pVirtuosoHost.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Virtuoso hostname. " +
                "Launch without arguments for usage guide."); 
        }
        if( ! ( pVirtuosoPort.isEmpty() || isNumeric(pVirtuosoPort) ) ) { 
            throw new Exception("Invalid argument: Virtuoso port. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(!pVirtuosoPort.isEmpty()) pVirtuosoPort = ":".
                concat(pVirtuosoPort);
        if(pVirtuosoUsername.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Virtuoso username. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(pVirtuosoPassword.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Virtuoso password. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(pVirtuosoRTGraph.isEmpty() && !"optimize-osm".equals(pWhat)) { 
            throw new Exception(
                    "Missing argument: Virtuoso RT graph. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(pVirtuosoOSMGraph.isEmpty() && !"optimize-rt".equals(pWhat)) { 
            throw new Exception(
                    "Missing argument: Virtuoso OSM graph. " + 
                    "Launch without arguments for usage guide."); 
        }
        if(pVirtuosoTargetGraph.isEmpty()) { 
            throw new Exception(
                    "Missing argument: Virtuoso target graph. " + 
                    "Launch without arguments for usage guide."); 
        }
        
        if(!("counties".equals(pWhat) || "municipalities".equals(pWhat) || 
            "roads-seed".equals(pWhat) || "roads-step".equals(pWhat) || 
            "elements-step1".equals(pWhat) || "elements-step2".equals(pWhat) ||
            "optimize-rt".equals(pWhat) || "optimize-osm".equals(pWhat) )) {
                throw new Exception("Invalid argument: what. " + 
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
                
        if((!pIdle.isEmpty()) && (!"roads-step".equals(pWhat))) {
            throw new Exception("Illegal argument: Idle time. " + 
                    "Launch without arguments for usage guide."); 
        }
                
        if((!pIdle.isEmpty()) && (!isNumeric(pIdle))) {
            throw new Exception("Invalid argument: Idle time. " + 
                    "Launch without arguments for usage guide."); 
        }
        
        if(pMunicipalityName.isEmpty() && ( "optimize-rt".equals(pWhat) || 
                "optimize-osm".equals(pWhat) ) ) {
            throw new Exception("Missing argument: municipality name" +
                    "Launch without arguments for usage guida.");
        }

    }
    
    private static void usageGuide() {
        
        System.out.println(
            "RT2OSM USAGE GUIDE                                          \n" +
            "--------------------------------------------------------------\n" +
            "This command line tool attempts to map the street graph made  \n" +
            "up with data coming from Regione Toscana, to the street graph \n" +                    
            "made up by using Open Street Map, and in particular: counties,\n" +          
            "municipalities, roads and road elements.                      \n" +        
            "                                                              \n" +
            "List of arguments:                                            \n" +
            "-h, --virt-host: hostname of the server where Virtuoso is     \n" +
            "    running                                                   \n" +
            "-p, --virt-port: port on which Virtuoso is listening          \n" +
            "-u, --virt-user: username for logging into Virtuoso           \n" +
            "-P, --virt-pwd: password for logging into Virtuoso             \n" +
            "-rg, --virt-rt-graph: Regione Toscana street graph URI        \n" +
            "-og, --virt-os-graph: Open Street Map street graph URI        \n" +
            "-tg, --virt-target-graph: target graph URI (the graph where   \n" +                    
            "     triples resulting from optimization or reconciliation    \n" +
            "     are stored)                                              \n" +
            "-w, --what: a mandatory specification of what have to be      \n" +
            "    reconciliated. Allowed valorizations are: counties,       \n" +
            "    municipalities, roads-seed, roads-step, elements-step1,   \n" + 
            "    elements-step2, optimize-rt, optimize-osm                 \n" +
            "-o, --output: the path to the output file where the triples   \n" +                    
            "    resulting from reconciliation will be written             \n" +
            "-l, --log: optional log level, allowed valorizations are:     \n" +                    
            "    off, minimal, verbose. Defaults to minimal.               \n" +
            "-i, --idle: optional idle time before querying the Virtuoso   \n" +                    
            "    RDF store, only used in the case of roads reconciliation  \n" +
            "-m, --municipality: mandatory for optimization, is the NAME of\n" +
            "    the Municipality for which the optimized graph must be    \n" +
            "    generated."        
         );
        
        System.exit(0);
        
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
                            
            LOGGER.log(Level.INFO, "Reconciliation complete. Triples are at "
                .concat(outf.getAbsolutePath()));
        
          } catch (RDFHandlerException e) {
            throw new RuntimeException(e);
        }

    }
        
}

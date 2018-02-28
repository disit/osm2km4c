# 	OSM2KM4C
#   Copyright (C) 2017 DISIT Lab http://www.disit.org - University of Florence
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as
#   published by the Free Software Foundation, either version 3 of the
#   License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>. 

README
------

rthousenum.jar è lo strumento da riga di comando che genera il file OSC che deve poi essere inviato in ingresso ad osmosis per l'applicazione vera e propria delle modifiche. Il file OSC generato contiene nodi OSM, ciascuno taggato con un numero civico ed un indirizzo completo, generati leggendo dal database Mysql sul quale si assume siano disponibili i dati messi a disposizione dalla Regione Toscana. 

Nella cartella triplification sono contenute le versioni degli script SQL di preparazione della triplificazione e degli script SML di configurazione di Sparqlify che erano lo stato dell'arte nel momento in cui la funzionalità di importazione dei numeri civici dalla Regione Toscana è stata introdotta, modificati opportunamente tenendo conto proprio della necessità di avere una configurazione iniziale aggiuntiva nella quale si vada ad indicare se debbano essere utilizzati i numeri civici nativi di OSM oppure quelli importati dalla Regione Toscana, e poi di personalizzazioni successive in cui si vada a tenere di conto di questa impostazione per la corretta generazione delle triple.

MS 29/06/2017
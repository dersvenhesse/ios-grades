//
//  Schools.swift
//  grades
//
//  Created by Sven Hesse on 10.02.16.
//  Copyright © 2016 Sven Hesse. All rights reserved.
//

/* 
 * Holds all aviable schools and their configuration.
 * The key should be unique.
 */
var schools = [
    
    // D
    School(
        key: "hda",
        name: "Hochschule Darmstadt",
        order: "D",
        url: "qis.h-da.de"
    ),
    
    // F
    School(
        key: "fhfrankfurt",
        name: "Frankfurt University of Applied Sciences",
        order: "F",
        url: "his-www.dv.fh-frankfurt.de"
    ),
    School(
        key: "fernunihagen",
        name: "FernUniversität Hagen",
        order: "F",
        url: "pos.fernuni-hagen.de"
    ),

    // G
    School(
        key: "hsgeisenheim",
        name: "Hochschule Geisenheim",
        order: "G",
        url: "qis.hs-geisenheim.de",
        urlTrail: "/hsg/rds?state="
    ),
    School(
        key: "unifrankfurt",
        name: "Goethe-Universität Frankfurt",
        order: "G",
        url: "qis.server.uni-frankfurt.de"
    ),
    
    // K
    School(
        key: "hskl",
        name: "Hochschule Kaiserslautern",
        order: "K",
        url: "qis.hs-kl.de"
    ),
    School(
        key: "tukl",
        name: "Technische Universität Kaiserslautern",
        order: "K",
        url: "qis.verw.uni-kl.de",
        urlListTrail: "%7Cstudiengang%3Astg%3DA44&expand=0&asi="
    ),
    School(
        key: "hskoblenz",
        name: "Hochschule Koblenz",
        order: "K",
        url: "qisserver.hs-koblenz.de"
    ),
    
    // M
    School(
        key: "hsmainz",
        name: "Hochschule Mainz",
        order: "M",
        url: "hip.hs-mainz.de"
    ),
    School(
        key: "hdm",
        name: "Hochschule der Medien",
        order: "M",
        url: "vw-online.hdm-stuttgart.de"
    ),
    
    // P
    School(
        key: "unimarburg",
        name: "Philipps-Universität Marburg",
        order: "P",
        url: "qis.verwaltung.uni-marburg.de"
    ),
    
    // R
    School(
        key: "hsrm",
        name: "Hochschule RheinMain",
        order: "R",
        url: "qis.hs-rm.de",
        gradelistClasses: ["tabelle1_alignright", "tabelle1_alignleft"]
    ),
    
    // T
    School(
        key: "hftl",
        name: "Hochschule für Telekommunikation Leipzig",
        order: "T",
        url: "qis.tel.hispro.de"
    ),
]
